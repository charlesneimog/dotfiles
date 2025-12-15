# Gera arte abstrata com círculos em 4K usando paleta Catppuccin
# Uso: python abstract_circle_art.py [opções]

# TODO: hopf_fibration
# TODO: Strange Attractors
# TODO: Hyperbolic Tiling
# TODO: Catalan Surfaces & Minimal Surfaces
# TODO: Geodesic Flows
# TODO: IFS (Iterated Function Systems)
# TODO: Delaunay Triangulation Flow


import sys
import random
import math
import argparse
from datetime import datetime
import pygame as pg
import numpy as np

try:
    from PIL import Image

    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

try:
    import cupy as xp  # GPU if available

    GPU_AVAILABLE = True
except ImportError:
    import numpy as xp  # CPU fallback

    GPU_AVAILABLE = False

# Inicializar pygame para renderização
pg.init()

# Enable GL multisampling
pg.display.gl_set_attribute(pg.GL_MULTISAMPLEBUFFERS, 1)
pg.display.gl_set_attribute(pg.GL_MULTISAMPLESAMPLES, 4)

# Paleta Catppuccin completa
CATPUCCIN_PALETTE = [
    "#f5e0dc",
    "#f2cdcd",
    "#f5c2e7",
    "#cba6f7",
    "#f38ba8",
    "#eba0ac",
    "#fab387",
    "#f9e2af",
    "#a6e3a1",
    "#94e2d5",
    "#89dceb",
    "#74c7ec",
    "#89b4fa",
    "#b4befe",
]

# Cores de fundo (tons mais escuros da paleta)
BACKGROUND_COLORS = ["#000000", "#1e1e2e", "#181825", "#11111b"]

# Estilos de arte disponíveis
ART_STYLES = [
    "concentric",
    "orbital",
    "lissajous",
    "lissajous3d",
    "random3d",
    "torus_knot",
    "grossman",
    "mondrian",
    "vasarely",
    "mesh_sphere",
    "mesh_sphere_squeezed",
    "circle_squeezed",
    "rotorelief",
    "strange_attractor",
    "delaunay_flow",
]


class AntiAliasedRenderer:
    def __init__(self, surf, scale):
        self.surf = surf
        self.scale = scale

    @staticmethod
    def _premul_rgb(color, a):
        return (int(color.r * a), int(color.g * a), int(color.b * a), int(255 * a))

    def draw_aa_circle(self, color, center, radius, width=0):
        r = radius
        size = r * 2 + 4
        tmp = pg.Surface((size, size), pg.SRCALPHA, 32)
        cx, cy = center
        ccx = size // 2
        ccy = size // 2
        for y in range(size):
            for x in range(size):
                dx = x - ccx
                dy = y - ccy
                dist = math.hypot(dx, dy)
                inside = dist <= r if width == 0 else (r - width <= dist <= r)
                if inside:
                    a = 1.0 - max(0.0, dist - r)
                    a = max(0.0, min(1.0, a))
                    tmp.set_at((x, y), self._premul_rgb(color, a))
        self.surf.blit(tmp, (cx - ccx, cy - ccy), special_flags=pg.BLEND_PREMULTIPLIED)

    def draw_aa_line(self, color, start, end, width):
        pg.draw.line(self.surf, color, start, end, max(1, int(width)))


class AbstractCircleArt:
    def __init__(self, width=1900, height=1200, supersample=2.0, antialias=True):
        # Target dimensions are the requested output size; render dimensions honor supersampling.
        self.target_width = int(width)
        self.target_height = int(height)
        self.supersample = supersample
        self.render_width = int(self.target_width * supersample)
        self.render_height = int(self.target_height * supersample)
        self.width = self.render_width
        self.height = self.render_height
        self.canvas = pg.Surface(
            (self.render_width, self.render_height), pg.SRCALPHA, 32
        )
        self.canvas.fill((0, 0, 0, 255))
        self.antialias = antialias
        self.aa = AntiAliasedRenderer(self.canvas, supersample)

    def to_render_coords(self, x, y):
        return int(x * self.supersample), int(y * self.supersample)

    def to_render_size(self, v):
        return int(v * self.supersample)

    def generate_background(self, bg_color=None):
        """Gera fundo com gradiente ou cor sólida"""
        if bg_color is None:
            bg_color = random.choice(BACKGROUND_COLORS)

        base = pg.Color(bg_color)
        ss = self.supersample
        if random.random() < 0.4:
            for y in range(self.height):
                t = y / self.height
                t = t * t * (3 - 2 * t)  # smoothstep
                n = 1.0 + random.uniform(-0.01, 0.01)
                r = int(base[0] * (0.7 + 0.3 * t) * n)
                g = int(base[1] * (0.7 + 0.3 * t) * n)
                b = int(base[2] * (0.7 + 0.3 * t) * n)
                pg.draw.line(self.canvas, (r, g, b, 255), (0, y), (self.width, y))
        else:
            self.canvas.fill((base.r, base.g, base.b, 255))

    def draw_concentric_circles(self, palette, complexity=8, max_size=400):
        """Círculos concêntricos"""
        centers = [
            (
                random.randint(self.target_width // 4, 3 * self.target_width // 4),
                random.randint(self.target_height // 4, 3 * self.target_height // 4),
            )
            for _ in range(complexity)
        ]
        for cx_t, cy_t in centers:
            main_rad_t = random.randint(max_size // 4, max_size // 2)
            rings = random.randint(3, 8)
            for i in range(rings):
                current_rad = self.to_render_size(
                    main_rad_t - i * (main_rad_t // rings)
                )
                if current_rad > 10:
                    thickness = self.to_render_size(random.randint(2, 8))
                    ring_color = pg.Color(random.choice(palette))
                    if self.antialias:
                        self.aa.draw_aa_circle(
                            ring_color,
                            self.to_render_coords(cx_t, cy_t),
                            current_rad,
                            thickness,
                        )
                    else:
                        pg.draw.circle(
                            self.canvas,
                            ring_color,
                            self.to_render_coords(cx_t, cy_t),
                            current_rad,
                            thickness,
                        )

    def draw_wave_pattern(self, palette, complexity=12, max_size=200):
        """Padrão de onda com círculos"""
        rows = complexity // 2 + 2
        cols = complexity // 2 + 2
        x_spacing = self.target_width // cols
        y_spacing = self.target_height // rows
        for i in range(rows + 1):
            for j in range(cols + 1):
                if random.random() < 0.7:
                    xt = j * x_spacing + random.randint(-x_spacing // 3, x_spacing // 3)
                    yt = i * y_spacing + random.randint(-y_spacing // 3, y_spacing // 3)
                    rad_t = int(
                        (max_size // 2) * (0.3 + 0.7 * abs((i + j) % 3 - 1.5) / 1.5)
                    )
                    rad = self.to_render_size(rad_t)
                    color = pg.Color(random.choice(palette))
                    thickness = self.to_render_size(
                        random.randint(3, max(3, rad_t // 6))
                    )
                    if self.antialias:
                        self.aa.draw_aa_circle(
                            color,
                            self.to_render_coords(xt, yt),
                            rad,
                            0 if random.random() < 0.6 else thickness,
                        )
                    else:
                        pg.draw.circle(
                            self.canvas,
                            color,
                            self.to_render_coords(xt, yt),
                            rad,
                            0 if random.random() < 0.6 else thickness,
                        )

    def draw_orbital_pattern(self, palette, complexity=6, max_size=400):
        """Padrão orbital com círculos"""
        main_circles = random.randint(2, 4)
        for _ in range(main_circles):
            cx_t = random.randint(self.target_width // 4, 3 * self.target_width // 4)
            cy_t = random.randint(self.target_height // 4, 3 * self.target_height // 4)
            main_rad_t = random.randint(max_size // 6, max_size // 4)
            main_color = pg.Color(random.choice(palette))
            main_rad = self.to_render_size(main_rad_t)
            if self.antialias:
                self.aa.draw_aa_circle(
                    main_color, self.to_render_coords(cx_t, cy_t), main_rad, 0
                )
            else:
                pg.draw.circle(
                    self.canvas, main_color, self.to_render_coords(cx_t, cy_t), main_rad
                )
            satellites = random.randint(4, 12)
            for i in range(satellites):
                angle = (i * 360 / satellites) * math.pi / 180
                orbit_radius_t = main_rad_t * random.randint(20, 35) // 10
                sat_x_t = cx_t + int(orbit_radius_t * math.cos(angle))
                sat_y_t = cy_t + int(orbit_radius_t * math.sin(angle))
                sat_rad = self.to_render_size(main_rad_t // random.randint(3, 6))
                sat_color = pg.Color(random.choice(palette))
                if self.antialias:
                    self.aa.draw_aa_circle(
                        sat_color,
                        self.to_render_coords(sat_x_t, sat_y_t),
                        sat_rad,
                        (
                            0
                            if random.random() >= 0.3
                            else self.to_render_size(random.randint(2, 5))
                        ),
                    )
                else:
                    pg.draw.circle(
                        self.canvas,
                        sat_color,
                        self.to_render_coords(sat_x_t, sat_y_t),
                        sat_rad,
                        (
                            0
                            if random.random() >= 0.3
                            else self.to_render_size(random.randint(2, 5))
                        ),
                    )

    def draw_lissajous(self, palette, complexity=6, max_size=350):
        cx, cy = self.width // 2, self.height // 2
        self.generate_background()

        # convert hex colors to RGB
        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        NUM_PHASORS = random.randint(6, 25)
        STEPS = 12000
        TIME_SCALE = 0.005
        RADIUS = self.to_render_size(max_size)
        stroke = self.to_render_size(random.uniform(1, 5))

        amps = [random.uniform(0.01, 0.5) for _ in range(NUM_PHASORS)]
        freqs = [random.uniform(0.3, 10.0) for _ in range(NUM_PHASORS)]
        phases = [random.uniform(0, math.tau) for _ in range(NUM_PHASORS)]

        color = hex_to_rgb(random.choice(palette))

        last_px = None

        for t in range(STEPS):
            tt = t * TIME_SCALE

            x = 0.0
            y = 0.0

            for i in range(NUM_PHASORS):
                x += amps[i] * math.cos(freqs[i] * tt + phases[i])
                y += amps[i] * math.sin(freqs[i] * tt + phases[i])

            px = cx + int(x * RADIUS)
            py = cy + int(y * RADIUS)

            if last_px is not None:
                if self.antialias:
                    self.aa.draw_aa_line(pg.Color(*color), last_px, (px, py), stroke)
                else:
                    pg.draw.line(self.canvas, color, last_px, (px, py), int(stroke))

            last_px = (px, py)

    def draw_lissajous3d(self, palette, complexity=8, max_size=350):
        """Renderiza uma curva de Lissajous em 3D com projeção 2D e gradiente de cor"""
        cx, cy = self.width // 2, self.height // 2
        self.generate_background()

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]

        STEPS = int(random.uniform(8000, 15000))
        TIME_SCALE = random.uniform(0.003, 0.01)
        RADIUS = self.to_render_size(max_size)
        stroke = self.to_render_size(max_size * 0.015)
        color = hex_to_rgb(random.choice(palette))

        # Frequências e fases independentes para cada eixo
        fx = random.uniform(0.4, 3.5)
        fy = random.uniform(0.4, 3.5)
        fz = random.uniform(0.4, 3.5)
        phx = random.uniform(0, math.tau)
        phy = random.uniform(0, math.tau)
        phz = random.uniform(0, math.tau)

        # Rotação 3D (yaw e pitch)
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 4, math.pi / 4)
        cos_yaw, sin_yaw = math.cos(yaw), math.sin(yaw)
        # select random color
        color = rgb_palette[random.randint(0, len(rgb_palette) - 1)]
        cos_pitch, sin_pitch = math.cos(pitch), math.sin(pitch)

        last_px = None
        for t in range(STEPS):
            tt = t * TIME_SCALE

            x3 = math.sin(fx * tt + phx)
            y3 = math.sin(fy * tt + phy)
            z3 = math.sin(fz * tt + phz)

            # Rotação em yaw
            xz = x3 * cos_yaw - z3 * sin_yaw
            zz = x3 * sin_yaw + z3 * cos_yaw
            # Rotação em pitch
            yz = y3 * cos_pitch - zz * sin_pitch
            zz = y3 * sin_pitch + zz * cos_pitch

            # Projeção simples ortográfica
            px = cx + int(xz * RADIUS)
            py = cy + int(yz * RADIUS)
            depth_alpha = int(80 + 175 * (1 + zz) / 2)  # mais próximo => mais opaco
            color_idx = t % len(rgb_palette)
            base_color = rgb_palette[color_idx]

            if last_px is not None:
                if self.antialias:
                    self.aa.draw_aa_line(pg.Color(*color), last_px, (px, py), stroke)
                else:
                    pg.draw.line(self.canvas, color, last_px, (px, py), int(stroke))
            last_px = (px, py)

    def draw_torus_knot(self, palette, complexity=12, max_size=300):
        """Generate (p,q) torus knot - beautiful interlaced patterns"""
        self.generate_background()
        cx, cy = self.width // 2, self.height // 2

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]

        base_size = max(self.target_width, self.target_height)
        radius = random.randint(2000, 5000)
        R = radius * random.uniform(0.45, 0.95)  # major radius
        r = radius * random.uniform(0.46, 0.78)  # tube radius
        inv_scale = 1.0 / max(1e-6, (R + r))

        # Choose coprime (p, q) for a proper knot
        while True:
            p = random.randint(8, 32)
            q = random.randint(8, 32)
            if math.gcd(p, q) == 1:
                break

        # Resolution scales with complexity for smooth curves
        steps = max(1000, int(complexity * 1000))
        dt = math.tau / steps

        # Random orientation
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        roll = random.uniform(-math.pi / 4, math.pi / 4)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)
        croll, sroll = math.cos(roll), math.sin(roll)

        def rotate(x, y, z):
            # roll
            y1 = y * croll - z * sroll
            z1 = y * sroll + z * croll
            x1 = x
            # pitch
            x2 = x1 * cpitch + z1 * spitch
            z2 = -x1 * spitch + z1 * cpitch
            y2 = y1
            # yaw
            x3 = x2 * cyaw - y2 * syaw
            y3 = x2 * syaw + y2 * cyaw
            return x3, y3, z2

        def project(x, y, z, persp=2.4):
            denom = max(0.45, persp - z)
            scale = radius / denom
            return cx + int(x * scale), cy + int(y * scale), z

        segments = []

        # Precompute palette cycling for subtle variation
        color_shift = random.randint(0, len(rgb_palette) - 1)

        t = 0.0
        last = None
        col = rgb_palette[
            (int(t / math.tau * len(rgb_palette)) + color_shift)
            % len(rgb_palette)
        ]
        while t <= math.tau + 1e-6:
            x = (R + r * math.cos(q * t)) * math.cos(p * t)
            y = (R + r * math.cos(q * t)) * math.sin(p * t)
            z = r * math.sin(q * t)
            xr, yr, zr = rotate(x * inv_scale, y * inv_scale, z * inv_scale)
            px, py, pz = project(xr, yr, zr)
            if last is not None:
                zavg = (pz + last[2]) * 0.5
                znorm = max(0.0, min(1.0, (zavg + 1) * 0.5))
                alpha = int(90 + 150 * znorm)
                stroke = random.uniform(3, 10)
                segments.append(
                    (zavg, col, alpha, stroke, (last[0], last[1]), (px, py))
                )
            last = (px, py, pz)
            t += dt

        # Depth sort for occlusion
        segments.sort(key=lambda s: s[0])
        for zavg, col, alpha, stroke, a, b in segments:
            if self.antialias:
                self.aa.draw_aa_line(pg.Color(*col, alpha), a, b, stroke)
            else:
                pg.draw.line(self.canvas, (*col, alpha), a, b, int(stroke))

    def draw_random3d(self, palette, complexity=10, max_size=350):
        """Forma 3D randômica centrada, usando a paleta fornecida"""
        width, height = self.canvas.get_size()
        cx, cy = width // 2, height // 2
        self.generate_background()

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]

        # Dimensão e rotação aleatória
        radius = self.to_render_size(
            int(min(self.target_width, self.target_height) * random.uniform(0.18, 0.32))
        )
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        roll = random.uniform(-math.pi / 4, math.pi / 4)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)
        croll, sroll = math.cos(roll), math.sin(roll)

        def rotate(vx, vy, vz):
            # roll
            y1 = vy * croll - vz * sroll
            z1 = vy * sroll + vz * croll
            x1 = vx
            # pitch
            x2 = x1 * cpitch + z1 * spitch
            z2 = -x1 * spitch + z1 * cpitch
            y2 = y1
            # yaw
            x3 = x2 * cyaw - y2 * syaw
            y3 = x2 * syaw + y2 * cyaw
            return x3, y3, z2

        layer = pg.Surface((width, height), pg.SRCALPHA)
        faces = max(4, complexity)
        base_color = random.choice(rgb_palette)
        for _ in range(faces):
            verts_3d = []
            for _ in range(random.randint(3, 5)):
                vx = random.uniform(-1, 1)
                vy = random.uniform(-1, 1)
                vz = random.uniform(-1, 1)
                verts_3d.append(rotate(vx, vy, vz))

            projected = []
            avg_z = 0
            for x3, y3, z3 in verts_3d:
                px = cx + int(x3 * radius)
                py = cy + int(y3 * radius)
                projected.append((px, py))
                avg_z += z3
            avg_z /= len(verts_3d)

            depth_alpha = int(90 + 140 * (avg_z + 1) / 2)
            color = (
                base_color[0],
                base_color[1],
                base_color[2],
                max(80, min(255, depth_alpha)),
            )
            pg.draw.polygon(layer, color, projected)
            pg.draw.lines(layer, (255, 255, 255, color[3]), True, projected, 2)

        self.canvas.blit(layer, (0, 0))

    def draw_grossman(self, palette, complexity=12, max_size=360):
        """Forma procedural inspirada em Bathsheba Grossman (quase-gyroid projetado)"""
        width, height = self.canvas.get_size()
        cx, cy = width // 2, height // 2
        self.generate_background()

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]

        RADIUS = self.to_render_size(
            int(min(self.target_width, self.target_height) * 0.25)
        )
        stroke = max(2, int(RADIUS * 0.01))

        # Rotação global
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)

        def rotate(x, y, z):
            xz = x * cyaw - z * syaw
            zz = x * syaw + z * cyaw
            yz = y * cpitch - zz * spitch
            zz = y * spitch + zz * cpitch
            return xz, yz, zz

        # Gyroid-like field sampled on rings and layers
        points = []
        layers = int(random.randint(20, 45))
        rings = max(8, complexity)
        for li in range(layers):
            theta = li / layers * math.pi
            ring_r = math.sin(theta) * RADIUS
            z = math.cos(theta) * RADIUS * 0.6
            for ri in range(rings):
                phi = ri / rings * math.tau
                gx = math.sin(phi) + math.sin(z / RADIUS + phi)
                gy = math.sin(phi + theta) + math.sin(theta)
                x = ring_r * math.cos(phi) * (0.9 + 0.2 * gx)
                y = ring_r * math.sin(phi) * (0.9 + 0.2 * gy)
                rx, ry, rz = rotate(x / RADIUS, y / RADIUS, z / RADIUS)
                px = cx + int(rx * RADIUS)
                py = cy + int(ry * RADIUS)
                points.append((px, py, rz))

        # Sort by depth for alpha falloff
        points.sort(key=lambda p: p[2])
        last = None
        color = random.choice(rgb_palette)
        for i, (px, py, dz) in enumerate(points):
            alpha = int(120 + 120 * (dz + 1) / 2)
            if last:
                pg.draw.line(self.canvas, color, (px, py), last, stroke)
            pg.draw.circle(self.canvas, color + (alpha,), (px, py), stroke + 1)
            last = (px, py)

    def draw_mondrian(self, palette, complexity=10, max_size=0):
        """Composição ao estilo Mondrian usando a paleta fornecida, centralizada e menor"""
        # não sobrescreve o fundo: usa o gerado em generate_background()
        self.generate_background()
        box_w = int(self.target_width * 0.35)
        box_h = int(self.target_height * 0.35)
        offset_x = (self.target_width - box_w) // 2
        offset_y = (self.target_height - box_h) // 2
        box_w_r = self.to_render_size(box_w)
        box_h_r = self.to_render_size(box_h)
        offset_x_r = self.to_render_size(offset_x)
        offset_y_r = self.to_render_size(offset_y)
        grid = [(offset_x_r, offset_y_r, box_w_r, box_h_r)]
        splits = max(6, complexity * 2)
        for _ in range(splits):
            x, y, w, h = grid.pop(random.randrange(len(grid)))
            if w < box_w * 0.12 or h < box_h * 0.12:
                grid.append((x, y, w, h))
                continue
            if w > h:
                cut = random.randint(int(w * 0.3), int(w * 0.7))
                grid.extend([(x, y, cut, h), (x + cut, y, w - cut, h)])
            else:
                cut = random.randint(int(h * 0.3), int(h * 0.7))
                grid.extend([(x, y, w, cut), (x, y + cut, w, h - cut)])

        border = max(6, min(box_w_r, box_h_r) // 70)
        line_color = pg.Color("#ffffff")
        for rx, ry, rw, rh in grid:
            if random.random() < 0.4:
                pg.draw.rect(
                    self.canvas,
                    pg.Color(random.choice(palette)),
                    pg.Rect(rx, ry, rw, rh),
                )
            pg.draw.rect(self.canvas, line_color, pg.Rect(rx, ry, rw, rh), width=border)

    def draw_vasarely(self, palette, complexity=12, max_size=300):
        """Op-art inspirado em Vasarely: grade curva com sombreamento centralizada"""
        self.generate_background()
        width, height = self.canvas.get_size()
        box_w = int(self.target_width * 0.45)
        box_h = int(self.target_height * 0.45)
        offset_x = (self.target_width - box_w) // 2
        offset_y = (self.target_height - box_h) // 2
        box_w_r = self.to_render_size(box_w)
        box_h_r = self.to_render_size(box_h)
        offset_x_r = self.to_render_size(offset_x)
        offset_y_r = self.to_render_size(offset_y)
        cols = max(10, complexity)
        rows = max(8, int(complexity * 0.8))
        cell_w = box_w_r // cols
        cell_h = box_h_r // rows
        warp_amp = 0.25 + random.random() * 0.35
        warp_freq = random.uniform(1.5, 3.5)
        depth_shade = random.uniform(0.4, 0.8)
        # random phases and jitter to avoid repetition
        warp_phase_r = random.uniform(0, math.tau)
        warp_phase_c = random.uniform(0, math.tau)

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]
        line_color = (255, 255, 255, 120)
        for i in range(rows + 1):
            for j in range(cols + 1):
                x = offset_x_r + j * cell_w
                y = offset_y_r + i * cell_h
                dx = (
                    math.sin(i / rows * math.pi * warp_freq + warp_phase_r)
                    * cell_w
                    * warp_amp
                )
                dy = (
                    math.sin(j / cols * math.pi * warp_freq + warp_phase_c)
                    * cell_h
                    * warp_amp
                )
                # slight jitter per node
                dx += random.uniform(-0.05, 0.05) * cell_w
                dy += random.uniform(-0.05, 0.05) * cell_h
                x += dx
                y += dy
                if j < cols and i < rows:
                    x2 = (
                        offset_x_r
                        + (j + 1) * cell_w
                        + math.sin(i / rows * math.pi * warp_freq + warp_phase_r)
                        * cell_w
                        * warp_amp
                    )
                    y2 = y
                    x3 = x
                    y3 = (
                        offset_y_r
                        + (i + 1) * cell_h
                        + math.sin(j / cols * math.pi * warp_freq + warp_phase_c)
                        * cell_h
                        * warp_amp
                    )
                    x4 = (
                        offset_x_r
                        + (j + 1) * cell_w
                        + math.sin((i + 1) / rows * math.pi * warp_freq + warp_phase_r)
                        * cell_w
                        * warp_amp
                    )
                    y4 = (
                        offset_y_r
                        + (i + 1) * cell_h
                        + math.sin((j + 1) / cols * math.pi * warp_freq + warp_phase_c)
                        * cell_h
                        * warp_amp
                    )
                    # jitter vertices individually
                    jitter = lambda v: v + random.uniform(-0.03, 0.03) * min(
                        cell_w, cell_h
                    )
                    poly = [
                        (jitter(x), jitter(y)),
                        (jitter(x2), jitter(y2)),
                        (jitter(x4), jitter(y4)),
                        (jitter(x3), jitter(y3)),
                    ]
                    base_color = random.choice(rgb_palette)
                    shade = depth_shade * (
                        math.sin((i + j) * 0.6 + random.random()) * 0.5 + 0.5
                    )
                    fill = (
                        int(base_color[0] * (0.7 + 0.3 * shade)),
                        int(base_color[1] * (0.7 + 0.3 * shade)),
                        int(base_color[2] * (0.7 + 0.3 * shade)),
                        255,
                    )
                    pg.draw.polygon(self.canvas, fill, poly)
                    pg.draw.polygon(self.canvas, line_color, poly, width=1)

    def draw_mesh_sphere(self, palette, complexity=14, max_size=220):
        """3D Catppuccin mesh sphere, small, centered, with large padding"""
        self.generate_background()
        cx, cy = self.width // 2, self.height // 2

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        # Sphere setup
        radius = self.to_render_size(
            int(min(self.target_width, self.target_height) * 0.5)
        )
        lat_lines = max(40, complexity)
        lon_lines = max(50, complexity * 2 // 3)
        segments = random.randint(500, 3500)
        rgb_palette = [hex_to_rgb(c) for c in palette]

        # Random orientation
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        roll = random.uniform(-math.pi / 4, math.pi / 4)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)
        croll, sroll = math.cos(roll), math.sin(roll)

        def rotate(x, y, z):
            # roll
            y1 = y * croll - z * sroll
            z1 = y * sroll + z * croll
            x1 = x
            # pitch
            x2 = x1 * cpitch + z1 * spitch
            z2 = -x1 * spitch + z1 * cpitch
            y2 = y1
            # yaw
            x3 = x2 * cyaw - y2 * syaw
            y3 = x2 * syaw + y2 * cyaw
            return x3, y3, z2

        def project(x, y, z, persp=2.4):
            # simple perspective projection
            denom = max(0.4, persp - z)
            scale = radius / denom
            return cx + int(x * scale), cy + int(y * scale), z

        segments_3d = []

        # Parallels
        for i in range(lat_lines + 1):
            theta = -math.pi / 2 + i * (math.pi / lat_lines)
            r = math.cos(theta)
            z = math.sin(theta)
            pts = []
            for s in range(segments + 1):
                phi = s / segments * math.tau
                x = r * math.cos(phi)
                y = r * math.sin(phi)
                xr, yr, zr = rotate(x, y, z)
                px, py, pz = project(xr, yr, zr)
                pts.append((px, py, pz))
            col = random.choice(rgb_palette)
            for a, b in zip(pts[:-1], pts[1:]):
                zavg = (a[2] + b[2]) * 0.5
                alpha = int(90 + 140 * (zavg + 1) * 0.5)
                stroke = random.uniform(0.5, 4)
                segments_3d.append(
                    (zavg, col, alpha, stroke, (a[0], a[1]), (b[0], b[1]))
                )

        # Meridians
        for j in range(lon_lines):
            phi = j / lon_lines * math.tau
            pts = []
            for s in range(segments + 1):
                theta = -math.pi / 2 + s / segments * math.pi
                x = math.cos(theta) * math.cos(phi)
                y = math.cos(theta) * math.sin(phi)
                z = math.sin(theta)
                xr, yr, zr = rotate(x, y, z)
                px, py, pz = project(xr, yr, zr)
                pts.append((px, py, pz))
            col = random.choice(rgb_palette)
            for a, b in zip(pts[:-1], pts[1:]):
                zavg = (a[2] + b[2]) * 0.5
                alpha = int(110 + 130 * (zavg + 1) * 0.5)
                stroke = self.to_render_size(1.2 + 1.6 * (zavg + 1) * 0.5)
                segments_3d.append(
                    (zavg, col, alpha, stroke, (a[0], a[1]), (b[0], b[1]))
                )

        # Depth sort and draw
        segments_3d.sort(key=lambda s: s[0])
        for zavg, col, alpha, stroke, a, b in segments_3d:
            if self.antialias:
                self.aa.draw_aa_line(pg.Color(*col, alpha), a, b, stroke)
            else:
                pg.draw.line(self.canvas, (*col, alpha), a, b, int(stroke))

        # Inner glow
        glow_color = random.choice(rgb_palette)
        glow_radius = int(radius * 0.42)
        for r in range(glow_radius, 0, -max(1, int(glow_radius / 22))):
            alpha = int(4 + 190 * (r / glow_radius) ** 1.4)
            pg.draw.circle(self.canvas, (*glow_color, alpha), (cx, cy), r, 1)

    def draw_mesh_sphere_squeezed(self, palette, complexity=14, max_size=220):
        """3D biomorphic Catppuccin mesh sphere squeezed by invisible forces"""
        cx, cy = self.width // 2, self.height // 2

        self.generate_background()

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        # Sphere setup (small, centered, lots of padding)
        radius = self.to_render_size(
            int(min(self.target_width, self.target_height) * random.uniform(0.4, 1))
        )
        lat_lines = random.randint(10, 200)
        lon_lines = random.randint(15, 300)
        segments = random.randint(1000, 6000)
        rgb_palette = [hex_to_rgb(c) for c in palette]

        # Random orientation
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        roll = random.uniform(-math.pi / 4, math.pi / 4)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)
        croll, sroll = math.cos(roll), math.sin(roll)

        # Biomorphic squeeze field
        warp_amp = random.uniform(0.25, 0.45)
        wf1, wf2, wf3 = [random.uniform(1.4, 3.6) for _ in range(3)]
        ph1, ph2, ph3 = [random.uniform(0, math.tau) for _ in range(3)]
        sx = random.uniform(0.65, 1.1)
        sy = random.uniform(0.65, 1.1)
        sz = random.uniform(0.65, 1.1)

        def rotate(x, y, z):
            # roll
            y1 = y * croll - z * sroll
            z1 = y * sroll + z * croll
            x1 = x
            # pitch
            x2 = x1 * cpitch + z1 * spitch
            z2 = -x1 * spitch + z1 * cpitch
            y2 = y1
            # yaw
            x3 = x2 * cyaw - y2 * syaw
            y3 = x2 * syaw + y2 * cyaw
            return x3, y3, z2

        def project(x, y, z, persp=2.6):
            denom = max(0.35, persp - z)
            scale = radius / denom
            return cx + int(x * scale), cy + int(y * scale), z

        segments_3d = []

        def squeeze_field(theta, phi):
            f = (
                math.sin(phi * wf1 + ph1) * math.cos(theta * wf2 + ph2)
                + math.sin((phi + theta) * wf3 + ph3)
            ) * 0.5
            return 1.0 - warp_amp * abs(f)

        # Parallels
        for i in range(lat_lines + 1):
            theta = -math.pi / 2 + i * (math.pi / lat_lines)
            r = math.cos(theta)
            base_z = math.sin(theta)
            pts = []
            for s in range(segments + 1):
                phi = s / segments * math.tau
                w = squeeze_field(theta, phi)
                x = r * math.cos(phi) * sx * w
                y = r * math.sin(phi) * sy * w
                z = base_z * sz * w
                xr, yr, zr = rotate(x, y, z)
                px, py, pz = project(xr, yr, zr)
                pts.append((px, py, pz))
            col = random.choice(rgb_palette)
            for a, b in zip(pts[:-1], pts[1:]):
                zavg = (a[2] + b[2]) * 0.5
                alpha = int(82 + 160 * (zavg + 1) * 0.5)
                stroke = self.to_render_size(0.9 + 1.6 * (zavg + 1) * 0.5)
                segments_3d.append(
                    (zavg, col, alpha, stroke, (a[0], a[1]), (b[0], b[1]))
                )

        # Meridians
        for j in range(lon_lines):
            phi = j / lon_lines * math.tau
            pts = []
            for s in range(segments + 1):
                theta = -math.pi / 2 + s / segments * math.pi
                w = squeeze_field(theta, phi)
                x = math.cos(theta) * math.cos(phi) * sx * w
                y = math.cos(theta) * math.sin(phi) * sy * w
                z = math.sin(theta) * sz * w
                xr, yr, zr = rotate(x, y, z)
                px, py, pz = project(xr, yr, zr)
                pts.append((px, py, pz))
            col = random.choice(rgb_palette)
            for a, b in zip(pts[:-1], pts[1:]):
                zavg = (a[2] + b[2]) * 0.5
                alpha = int(96 + 150 * (zavg + 1) * 0.5)
                stroke = random.uniform(0.2, 3)
                segments_3d.append(
                    (zavg, col, alpha, stroke, (a[0], a[1]), (b[0], b[1]))
                )

        # Depth sort and draw
        segments_3d.sort(key=lambda s: s[0])
        for zavg, col, alpha, stroke, a, b in segments_3d:
            if self.antialias:
                self.aa.draw_aa_line(pg.Color(*col, alpha), a, b, stroke)
            else:
                pg.draw.line(self.canvas, (*col, alpha), a, b, int(stroke))

    def draw_circle_squeezed(self, palette, complexity=14, max_size=320):
        """circle_squeezed-inspired optical disks (Duchamp) centered on dark background"""
        cx, cy = self.width // 2, self.height // 2
        self.generate_background()

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        radius = self.to_render_size(
            int(min(self.target_width, self.target_height) * random.uniform(0.2, 0.3))
        )
        rings = random.randint(8, 64)
        pts_per_ring = random.randint(200, 300)
        layer = pg.Surface((self.width, self.height), pg.SRCALPHA)
        rgb_palette = [hex_to_rgb(c) for c in palette]

        for i in range(rings):
            t = i / rings
            angle = t * math.pi * 0.6 + random.uniform(-0.05, 0.05)
            a = radius * (1.0 - 0.65 * t) * random.uniform(0.92, 1.08)
            b = a * (0.82 + 0.3 * math.sin(t * math.pi * 2 + random.random()))
            wobble = 0.04 + 0.06 * random.random()
            color = random.choice(rgb_palette)
            alpha = int(140 + 90 * (1 - t))
            stroke = random.uniform(1, 15)

            pts = []
            ca, sa = math.cos(angle), math.sin(angle)
            for k in range(pts_per_ring + 1):
                p = k / pts_per_ring * math.tau
                rmod = 1.0 + wobble * math.sin(p * 5 + i)
                x = a * math.cos(p) * rmod
                y = b * math.sin(p) * rmod
                xr = x * ca - y * sa
                yr = x * sa + y * ca
                pts.append((cx + int(xr), cy + int(yr)))

            for p1, p2 in zip(pts[:-1], pts[1:]):
                if self.antialias:
                    self.aa.draw_aa_line(pg.Color(*color, alpha), p1, p2, stroke)
                else:
                    pg.draw.line(layer, (*color, alpha), p1, p2, int(stroke))

        self.canvas.blit(layer, (0, 0))

    def draw_rotorelief(self, palette, complexity=10, max_size=320):
        """
        Rotorelief-inspired optical disk: concentric outlined circles on a spiral,
        centered on a dark Catppuccin background.
        """
        self.generate_background()
        cx, cy = self.width // 2, self.height // 2

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        # Parameters inspired by the reference snippet
        num_circles = random.randint(10, 35)
        base_r = self.to_render_size(20)
        spiral_factor = self.to_render_size(14)
        support_r = (base_r * (num_circles + 1)) + (spiral_factor + 1)
        stroke = self.to_render_size(3)
        angle_offset = random.random() * math.tau  # static “frame” of a rotating disk

        # Support circle
        support_color = pg.Color(*hex_to_rgb(random.choice(palette)))
        if self.antialias:
            self.aa.draw_aa_circle(support_color, (cx, cy), support_r, stroke)
        else:
            pg.draw.circle(self.canvas, support_color, (cx, cy), support_r, stroke)

        # Spiral-displaced outlined circles
        radius = base_r
        palette_rgb = [hex_to_rgb(c) for c in palette]
        for i in range(num_circles + 1):
            ang = i * math.tau / ((num_circles / 2) + 1) + angle_offset
            x = math.cos(ang) * spiral_factor
            y = math.sin(ang) * spiral_factor
            col = pg.Color(*random.choice(palette_rgb))
            if self.antialias:
                self.aa.draw_aa_circle(col, (cx + int(x), cy + int(y)), radius, stroke)
            else:
                pg.draw.circle(
                    self.canvas, col, (cx + int(x), cy + int(y)), radius, stroke
                )
            radius += spiral_factor

    def draw_delaunay_flow(self, palette, complexity=15, max_size=400):
        """Centered Delaunay triangulation flow with Catppuccin palette"""
        self.generate_background()
        cx, cy = self.width // 2, self.height // 2

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        rgb_palette = [hex_to_rgb(c) for c in palette]

        span = min(self.target_width, self.target_height) * 0.6
        span = min(span, max_size)
        base_scale = self.to_render_size(int(span))

        point_count = max(40, min(260, int(60 + complexity * 8)))
        swirl = 0.4 + 0.3 * random.random()
        freq = 1.3 + random.random() * 1.7
        jitter = base_scale * 0.015

        points = []
        for i in range(point_count):
            t = i / point_count
            ang = random.random() * math.tau
            flow = swirl * math.sin(freq * ang + t * math.tau)
            r = base_scale * (0.25 + 0.75 * (random.random() ** 0.9))
            px = cx + math.cos(ang + flow) * r + random.uniform(-jitter, jitter)
            py = cy + math.sin(ang + flow) * r + random.uniform(-jitter, jitter)
            points.append((px, py))

        # Bowyer-Watson Delaunay triangulation (2D)
        # Super triangle far outside the point cloud
        st_scale = base_scale * 8
        super_pts = [
            (cx - st_scale, cy - st_scale * 0.5),
            (cx, cy + st_scale * 1.2),
            (cx + st_scale, cy - st_scale * 0.5),
        ]

        all_pts = points + super_pts
        super_idxs = (len(points), len(points) + 1, len(points) + 2)

        def circumcircle(p1, p2, p3):
            ax, ay = p1
            bx, by = p2
            cx_, cy_ = p3
            d = 2 * (ax * (by - cy_) + bx * (cy_ - ay) + cx_ * (ay - by))
            if abs(d) < 1e-12:
                return (0.0, 0.0, float("inf"))
            ux = (
                (ax * ax + ay * ay) * (by - cy_)
                + (bx * bx + by * by) * (cy_ - ay)
                + (cx_ * cx_ + cy_ * cy_) * (ay - by)
            ) / d
            uy = (
                (ax * ax + ay * ay) * (cx_ - bx)
                + (bx * bx + by * by) * (ax - cx_)
                + (cx_ * cx_ + cy_ * cy_) * (bx - ax)
            ) / d
            rsq = (ux - ax) ** 2 + (uy - ay) ** 2
            return (ux, uy, rsq)

        triangles = [(super_idxs[0], super_idxs[1], super_idxs[2])]

        for idx, p in enumerate(points):
            px, py = p
            bad = []
            circs = []
            for tri in triangles:
                c = circumcircle(all_pts[tri[0]], all_pts[tri[1]], all_pts[tri[2]])
                circs.append(c)
            for t_idx, tri in enumerate(list(triangles)):
                ux, uy, rsq = circs[t_idx]
                if rsq == float("inf"):
                    continue
                if (ux - px) ** 2 + (uy - py) ** 2 <= rsq * 1.000001:
                    bad.append(tri)

            # Find boundary edges
            edge_counts = {}
            for tri in bad:
                for e in [(tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0])]:
                    key = tuple(sorted(e))
                    edge_counts[key] = edge_counts.get(key, 0) + 1

            triangles = [t for t in triangles if t not in bad]

            boundary = [e for e, count in edge_counts.items() if count == 1]
            all_pts.append(p)
            p_idx = len(all_pts) - 1
            for e in boundary:
                triangles.append((e[0], e[1], p_idx))

        # Remove triangles connected to super triangle vertices
        triangles = [tri for tri in triangles if not any(v in super_idxs for v in tri)]

        thickness = self.to_render_size(1.0 + complexity / 25.0)
        outline = max(1, int(thickness))
        layer = pg.Surface((self.width, self.height), pg.SRCALPHA)

        for i, tri in enumerate(triangles):
            p1 = all_pts[tri[0]]
            p2 = all_pts[tri[1]]
            p3 = all_pts[tri[2]]
            cx_tri = (p1[0] + p2[0] + p3[0]) / 3.0
            cy_tri = (p1[1] + p2[1] + p3[1]) / 3.0
            dx = (cx_tri - cx) / (base_scale + 1e-5)
            dy = (cy_tri - cy) / (base_scale + 1e-5)
            ang = (math.atan2(dy, dx) + math.tau) % math.tau
            dist = min(1.0, math.sqrt(dx * dx + dy * dy))
            pal_idx = int(((ang / math.tau) * len(rgb_palette) + i) % len(rgb_palette))
            base_col = rgb_palette[pal_idx]
            shade = 0.55 + 0.35 * (1.0 - dist)
            fill = (
                int(base_col[0] * shade),
                int(base_col[1] * shade),
                int(base_col[2] * shade),
                int(150 + 90 * (1.0 - dist)),
            )
            poly = [(int(p1[0]), int(p1[1])), (int(p2[0]), int(p2[1])), (int(p3[0]), int(p3[1]))]
            pg.draw.polygon(layer, fill, poly)

        # Outline pass for clarity
        for tri in triangles:
            p1 = all_pts[tri[0]]
            p2 = all_pts[tri[1]]
            p3 = all_pts[tri[2]]
            edges = [
                ((int(p1[0]), int(p1[1])), (int(p2[0]), int(p2[1]))),
                ((int(p2[0]), int(p2[1])), (int(p3[0]), int(p3[1]))),
                ((int(p3[0]), int(p3[1])), (int(p1[0]), int(p1[1]))),
            ]
            col = pg.Color(*random.choice(rgb_palette), 200)
            for a, b in edges:
                if self.antialias:
                    self.aa.draw_aa_line(col, a, b, thickness)
                else:
                    pg.draw.line(layer, col, a, b, outline)

        self.canvas.blit(layer, (0, 0))

    def draw_strange_attractor(self, palette, complexity=15, max_size=350):
        """Generate 3D strange attractor - chaotic system visualization"""
        self.generate_background()
        cx, cy = self.width // 2, self.height // 2

        def hex_to_rgb(h):
            h = h.lstrip("#")
            return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

        radius = random.randint(1500, 3000)
        radius = self.to_render_size(int(radius))

        steps = int(max(2000, complexity * 5000))
        dt = 0.01 * (0.8 + min(1.4, complexity / 25.0))
        transient = min(1000, steps // 4)
        attractor_type = random.choice(["lorenz", "rossler", "aizawa"])
        rgb_palette = [hex_to_rgb(c) for c in palette]

        points = xp.zeros((steps, 3), dtype=float)
        x, y, z = 0.1, 0.0, 0.0

        def deriv(px, py, pz):
            if attractor_type == "lorenz":
                sigma, rho, beta = 10.0, 28.0, 2.667
                dx = sigma * (py - px)
                dy = px * (rho - pz) - py
                dz = px * py - beta * pz
            elif attractor_type == "rossler":
                a, b, c = 0.2, 0.2, 5.7
                dx = -py - pz
                dy = px + a * py
                dz = b + pz * (px - c)
            else:
                a, b, c, d, e, f = 0.95, 0.7, 0.6, 3.5, 0.25, 0.1
                dx = (pz - b) * px - d * py
                dy = d * px + (pz - b) * py
                dz = (
                    c
                    + a * pz
                    - (pz ** 3) / 3.0
                    - (px ** 2 + py ** 2) * (1 + e * pz)
                    + f * pz * (px ** 3)
                )
            return dx, dy, dz

        for i in range(steps):
            k1x, k1y, k1z = deriv(x, y, z)
            k2x, k2y, k2z = deriv(
                x + 0.5 * dt * k1x, y + 0.5 * dt * k1y, z + 0.5 * dt * k1z
            )
            k3x, k3y, k3z = deriv(
                x + 0.5 * dt * k2x, y + 0.5 * dt * k2y, z + 0.5 * dt * k2z
            )
            k4x, k4y, k4z = deriv(x + dt * k3x, y + dt * k3y, z + dt * k3z)

            x += dt * (k1x + 2 * k2x + 2 * k3x + k4x) / 6.0
            y += dt * (k1y + 2 * k2y + 2 * k3y + k4y) / 6.0
            z += dt * (k1z + 2 * k2z + 2 * k3z + k4z) / 6.0

            points[i, 0] = x
            points[i, 1] = y
            points[i, 2] = z

        pts = points[transient:]
        if GPU_AVAILABLE:
            pts = xp.asnumpy(pts)
        else:
            pts = np.asarray(pts)

        if pts.size == 0:
            return

        max_extent = float(np.max(np.abs(pts)))
        max_extent = max(max_extent, 1e-5)
        pts = pts / max_extent

        # Random orientation
        yaw = random.uniform(0, math.tau)
        pitch = random.uniform(-math.pi / 3, math.pi / 3)
        roll = random.uniform(-math.pi / 4, math.pi / 4)
        cyaw, syaw = math.cos(yaw), math.sin(yaw)
        cpitch, spitch = math.cos(pitch), math.sin(pitch)
        croll, sroll = math.cos(roll), math.sin(roll)

        # Apply rotation (roll -> pitch -> yaw)
        x0 = pts[:, 0]
        y0 = pts[:, 1] * croll - pts[:, 2] * sroll
        z0 = pts[:, 1] * sroll + pts[:, 2] * croll
        x1 = x0 * cpitch + z0 * spitch
        z1 = -x0 * spitch + z0 * cpitch
        y1 = y0
        xr = x1 * cyaw - y1 * syaw
        yr = x1 * syaw + y1 * cyaw
        zr = z1

        # Perspective projection
        denom = np.maximum(0.4, 2.4 - zr)
        scaled = radius * (0.9 + 0.2 * random.random())
        scale = scaled / denom
        px = cx + (xr * scale).astype(int)
        py = cy + (yr * scale).astype(int)

        zmin = float(np.min(zr))
        zmax = float(np.max(zr))
        zrange = max(zmax - zmin, 1e-5)
        znorm = (zr - zmin) / zrange

        # Speed for velocity-based coloring
        speeds = np.linalg.norm(np.diff(np.stack([xr, yr, zr], axis=1), axis=0), axis=1)
        if speeds.size:
            speed_norm = speeds / (speeds.max() + 1e-6)
            speed_norm = np.append(speed_norm, speed_norm[-1])
        else:
            speed_norm = np.zeros_like(px, dtype=float)

        color_mode = random.choice(["cycle", "depth", "velocity"])
        thickness_base = self.to_render_size(1.0 + 2.0 * (complexity / 30.0))

        for i in range(len(px) - 1):
            zmid = (zr[i] + zr[i + 1]) * 0.5
            zmid_norm = (zmid - zmin) / zrange
            if color_mode == "cycle":
                base_color = rgb_palette[i % len(rgb_palette)]
            elif color_mode == "depth":
                idx = int(zmid_norm * (len(rgb_palette) - 1))
                base_color = rgb_palette[idx]
            else:
                idx = int(speed_norm[i] * (len(rgb_palette) - 1))
                base_color = rgb_palette[idx]

            alpha = int(90 + 150 * zmid_norm)
            thickness = thickness_base * (0.7 + 0.6 * zmid_norm)
            start = (int(px[i]), int(py[i]))
            end = (int(px[i + 1]), int(py[i + 1]))

            if self.antialias:
                self.aa.draw_aa_line(pg.Color(*base_color, alpha), start, end, thickness)
            else:
                pg.draw.line(self.canvas, (*base_color, alpha), start, end, int(thickness))

    def generate_art(
        self,
        style,
        palette=None,
        complexity=15,
        max_size=300,
        layers=2,
        output_file=None,
    ):
        """
        Gera arte abstrata

        Args:
            style: Estilo de arte (ou 'random' para escolher aleatório)
            palette: Lista de cores em formato hexadecimal
            complexity: Complexidade (5-30)
            max_size: Tamanho máximo dos círculos
            layers: Número de camadas/estilos a combinar
            output_file: Caminho do arquivo de saída
        """
        if palette is None:
            palette = CATPUCCIN_PALETTE

        # Escolher estilo se 'random'
        if style == "random":
            style = random.choice(ART_STYLES)

        # Garantir valores dentro dos limites
        complexity = max(5, min(30, complexity))
        max_size = max(50, min(500, max_size))
        layers = max(1, min(3, layers))

        print(f"Generating {style} art...")
        print(f"  Palette: {len(palette)} colors")
        print(f"  Complexity: {complexity}")
        print(f"  Max size: {max_size}")
        print(f"  Layers: {layers}")

        # Gerar fundo
        self.generate_background()

        # Lista de métodos de desenho
        draw_methods = {
            "concentric": self.draw_concentric_circles,
            "orbital": self.draw_orbital_pattern,
            "lissajous": self.draw_lissajous,
            "lissajous3d": self.draw_lissajous3d,
            "random3d": self.draw_random3d,
            "torus_knot": self.draw_torus_knot,
            "grossman": self.draw_grossman,
            "mondrian": self.draw_mondrian,
            "vasarely": self.draw_vasarely,
            "mesh_sphere": self.draw_mesh_sphere,
            "mesh_sphere_squeezed": self.draw_mesh_sphere_squeezed,
            "circle_squeezed": self.draw_circle_squeezed,
            "rotorelief": self.draw_rotorelief,
            "strange_attractor": self.draw_strange_attractor,
            "delaunay_flow": self.draw_delaunay_flow,
        }

        draw_methods[style](palette, int(complexity), max_size)

        # Downscale with smoothscale for SSAA
        if self.supersample != 1.0:
            final_surface = pg.transform.smoothscale(
                self.canvas, (self.target_width, self.target_height)
            )
        else:
            final_surface = self.canvas

        # Salvar arquivo
        if output_file is None:
            output_file = f"output.png"

        # Certificar que é PNG
        if not output_file.lower().endswith(".png"):
            output_file += ".png"

        print(f"Saving to: {output_file}")
        if PIL_AVAILABLE:
            mode = "RGBA"
            raw_str = pg.image.tostring(final_surface, mode, False)
            img = Image.frombytes(mode, final_surface.get_size(), raw_str)
            img.save(output_file, format="PNG", compress_level=1)
        else:
            pg.image.save(final_surface, output_file)
        print("Done!")

        return output_file


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Generate abstract circle art in 4K using Catppuccin palette",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python abstract_circle_art.py --style chaotic
  python abstract_circle_art.py --style random --complexity 20 --size 400
  python abstract_circle_art.py --style clusters --layers 3 --output my_art.png
  python abstract_circle_art.py --style wave --custom-colors "#ff0000 #00ff00 #0000ff"
        """,
    )

    parser.add_argument(
        "--style",
        type=str,
        default="random",
        choices=["random"] + ART_STYLES,
        help="Art style (default: random)",
    )

    parser.add_argument(
        "--width", type=int, default=1900 * 2, help="Output width (default: 1900)"
    )

    parser.add_argument(
        "--height", type=int, default=1200 * 2, help="Output height (default: 1200)"
    )

    parser.add_argument(
        "--complexity",
        type=int,
        default=5,
        help="Complexity/density (5-30, default: 15)",
    )

    parser.add_argument(
        "--size",
        type=int,
        default=300,
        help="Maximum circle size (50-500, default: 300)",
    )

    parser.add_argument(
        "--layers",
        type=int,
        default=2,
        help="Number of layers to combine (1-3, default: 2)",
    )

    parser.add_argument(
        "--output", type=str, help="Output filename (default: auto-generated)"
    )

    parser.add_argument(
        "--custom-colors",
        type=str,
        help="Custom color palette as space-separated hex colors",
    )

    parser.add_argument(
        "--list-styles", action="store_true", help="List available art styles"
    )

    parser.add_argument("--seed", type=int, help="Random seed for reproducible results")

    parser.add_argument(
        "--supersample",
        type=float,
        default=2.0,
        help="Supersample factor (default: 2.0)",
    )
    parser.add_argument(
        "--quality",
        type=str,
        choices=["low", "medium", "high", "ultra"],
        default="high",
        help="Quality preset",
    )
    parser.add_argument(
        "--antialias",
        type=lambda v: v.lower() == "true",
        default=True,
        help="Enable antialiasing (default: true)",
    )
    parser.add_argument(
        "--use-pil",
        type=lambda v: v.lower() == "true",
        default=True,
        help="Use Pillow for saving if available",
    )

    return parser.parse_args()


def main():
    """Main function"""
    args = parse_arguments()

    # Listar estilos se solicitado
    if args.list_styles:
        print("Available art styles:")
        for style in ART_STYLES:
            print(f"  - {style}")
        return

    # Configurar seed aleatória
    if args.seed is not None:
        random.seed(args.seed)

    # Preparar paleta de cores
    if args.custom_colors:
        palette = args.custom_colors.split()
        print(f"Using custom palette with {len(palette)} colors")
    else:
        palette = CATPUCCIN_PALETTE

    ss = args.supersample
    if args.quality == "low":
        ss = 1.0
    elif args.quality == "medium":
        ss = max(args.supersample, 1.5)
    elif args.quality == "ultra":
        ss = max(args.supersample, 3)
    else:
        ss = args.supersample

    # Criar gerador de arte
    art_generator = AbstractCircleArt(
        width=args.width, height=args.height, supersample=ss, antialias=args.antialias
    )

    # Gerar arte
    output_file = art_generator.generate_art(
        style=args.style,
        palette=palette,
        complexity=args.complexity,
        max_size=args.size,
        layers=args.layers,
        output_file=args.output,
    )

    print(f"\nArt generated successfully!")
    print(f"File: {output_file}")
    print(f"Size: {args.width}x{args.height} (4K)")


if __name__ == "__main__":
    main()

# Before/after:
# - Before: jagged edges, linear gradients, default save
