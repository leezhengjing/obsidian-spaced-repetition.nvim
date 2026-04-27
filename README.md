# obsidian-spaced-repetition.nvim

A Neovim plugin that brings the power of [Obsidian Spaced Repetition](https://github.com/st3v3nmw/obsidian-spaced-repetition) to your favorite terminal editor. Review your Obsidian flashcards directly in Neovim with full compatibility and image support.

## ✨ Features

- **Full Obsidian Compatibility**: Uses the same `<!--SR:...-->` comment format. Your scheduling data stays in sync between Neovim and the Obsidian app.
- **Support for All Card Types**:
  - Single-line (`Question ::: Answer`)
  - Single-line reversible (`Question :::: Answer`)
  - Multi-line (`Question ? Answer`)
  - Multi-line reversible (`Question ?? Answer`)
- **Telescope Integration**: Browse and select decks with live statistics (Due, New, Total).
- **Distraction-Free UI**: Native floating window for reviews with automatic focus and markdown highlighting.
- **Image Support**: Renders images (including `.avif`, `.png`, `.jpg`) directly in the review window using `image.nvim`.
- **SM-2 Algorithm**: Robust scheduling based on the standard SuperMemo-2 algorithm.

## 🚀 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "leezhengjing/obsidian-spaced-repetition.nvim",
    dependencies = { 
        "nvim-telescope/telescope.nvim",
        "3rd/image.nvim", -- Optional: For image support
    },
    config = function()
        require("obsidian-spaced-repetition").setup({
            vault_path = "/path/to/your/obsidian/vault",
            flashcard_tags = { "cs3211", "algorithms" },
            -- Optional configuration
            single_line_separator = ":::",
            single_line_reversed_separator = "::::",
        })
    end,
    keys = {
        { "<leader>or", "<cmd>ObsidianSRReview<cr>", desc = "Obsidian Spaced Repetition Review" },
    },
}
```

## 🛠️ Configuration

| Option | Default | Description |
| --- | --- | --- |
| `vault_path` | `""` | **Required**. Absolute path to your Obsidian vault. |
| `flashcard_tags` | `{"#flashcards"}` | Tags used to identify flashcard notes (prefix `#` is optional). |
| `single_line_separator` | `":::"` | Separator for single-line cards. |
| `single_line_reversed_separator` | `"::::"` | Separator for reversible single-line cards. |
| `default_ease` | `250` | Starting ease factor for new cards. |

## 🖼️ Image Support Setup (Important)

To enable images in the floating review window:

1.  Install **ImageMagick** and **magick** lua library:
    ```bash
    brew install imagemagick
    luarocks --local install magick
    ```
2.  If using **tmux**, allow passthrough in `~/.tmux.conf`:
    ```tmux
    set -g allow-passthrough on
    ```
3.  Configure `image.nvim` to use the `kitty` backend (recommended for Ghostty/Kitty/WezTerm).

## ⌨️ Review Controls

Once the review window is open:
- `<Space>` or `<CR>`: Show Answer
- `1`: Again (Wrong)
- `2`: Hard
- `3`: Good
- `4`: Easy
- `q` or `<Esc>`: Quit review

## ❓ FAQ & Troubleshooting

**Q: No decks are appearing in Telescope.**
- Verify `vault_path` is an absolute path.
- Check if your tags match exactly (the plugin searches YAML `tags:` and inline `#tags`).
- Run `:messages` to see debug output.

**Q: Images are not rendering.**
- Ensure `image.nvim` is working in standard markdown files first.
- If using `tmux`, verify `allow-passthrough` is enabled.
- Ensure your terminal (like Ghostty) supports the Kitty graphics protocol.

**Q: Why the `:::` separator?**
- Default Obsidian `::` often conflicts with C++ syntax (`std::vector`). We use `:::` by default to remain code-friendly, but you can change it back in `opts`.

## 📄 License
MIT
