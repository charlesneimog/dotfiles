import subprocess
import argparse
import os
from html import escape
import re

def should_ignore_diff(line_added, line_removed):
    a = line_added[1:].strip()
    b = line_removed[1:].strip()

    trivial_changes = [
        (r'\\citet\b', r'\\textcite'),
        (r'\\citep\b', r'\\parencite'),
    ]

    for old, new in trivial_changes:
        a_sub = re.sub(old, '__CMD__', a)
        b_sub = re.sub(new, '__CMD__', b)
        if a_sub == b_sub:
            return True
    return False

def get_diff(repo_path):
    result = subprocess.run(
        ['git', 'diff', 'HEAD', '--', '*.tex'],
        cwd=repo_path,
        capture_output=True,
        text=True
    )
    return result.stdout

def diff_to_html(diff_text):
    html_lines = []
    html_lines.append('<html><head><meta charset="UTF-8"><title>.tex Git Diff</title>')
    html_lines.append("""
<style>
    body {
        font-family: monospace;
        white-space: pre-wrap;
        word-break: break-word;
        background: #f9f9f9;
        padding: 1em;
        max-width: 90%;
        margin-left: 5%;
    }
    .add  { background-color: #e6ffe6; color: #006600; }
    .del  { background-color: #ffe6e6; color: #990000; }
    .meta { color: #999; }
</style>
</head><body>
    """)

    lines = diff_text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('-') and i + 1 < len(lines) and lines[i + 1].startswith('+'):
            removed = line
            added = lines[i + 1]
            if should_ignore_diff(added, removed):
                i += 2
                continue  # Skip both lines
        escaped = escape(line)
        if line.startswith('+') and not line.startswith('+++'):
            html_lines.append(f'<span class="add">{escaped}</span><br>')
        elif line.startswith('-') and not line.startswith('---'):
            html_lines.append(f'<span class="del">{escaped}</span><br>')
        elif line.startswith(('@@', 'diff', 'index', '---', '+++')):
            html_lines.append(f'<span class="meta">{escaped}</span><br>')
        else:
            html_lines.append(f'{escaped}<br>')
        i += 1

    html_lines.append('</body></html>')
    return '\n'.join(html_lines)

def main():
    parser = argparse.ArgumentParser(description='Generate colored HTML diff for .tex files in a Git repo.')
    parser.add_argument('--repo', '-r', default='.', help='Path to the Git repository (default: current directory)')
    args = parser.parse_args()
    repo_path = os.path.abspath(args.repo)

    diff_text = get_diff(repo_path)
    if not diff_text.strip():
        print("No .tex diffs found.")
        return

    html_output = diff_to_html(diff_text)
    output_path = os.path.join(repo_path, 'diff_output.html')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_output)

    print(f"Colored diff written to: {output_path}")

if __name__ == '__main__':
    main()

