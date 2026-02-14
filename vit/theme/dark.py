# VIT — Pure Dark Monochrome Theme
# Uses urwid palette format:
#   (name, fg_16, bg_16, mono_attr, fg_256, bg_256)
# All grays, transparent where possible.

theme = [
    # Column headers — dark bg, muted text
    ('list-header', '', '', '', '', ''),
    ('list-header-column', 'light gray', 'dark gray', '', '#d4d4d4', 'g15'),
    ('list-header-column-separator', 'light gray', 'dark gray', '', '#555555', 'g15'),

    # Alternating rows — subtle stripe
    ('striped-table-row', 'white', 'black', '', '#bbbbbb', 'g7'),

    # Focused/selected row — inverted gray
    ('reveal focus', 'black', 'light gray', 'standout', 'black', '#d4d4d4'),

    # Status bar messages
    ('message status', 'white', 'dark gray', 'standout', '#d4d4d4', 'g19'),
    ('message error', 'white', 'dark red', 'standout', '#d4d4d4', '#331111'),

    # Bottom status line
    ('status', 'light gray', 'black', '', '#888888', 'g3'),

    # Flash animation (task modified feedback)
    ('flash off', 'black', 'black', 'standout', 'black', 'black'),
    ('flash on', 'white', 'black', 'standout', '#d4d4d4', 'g11'),

    # Popups / dialogs
    ('pop_up', 'white', 'black', '', '#d4d4d4', 'g7'),

    # Buttons in confirmation dialogs
    ('button action', 'black', 'light gray', '', 'black', '#d4d4d4'),
    ('button cancel', 'light gray', 'dark gray', '', '#888888', 'g15'),
]
