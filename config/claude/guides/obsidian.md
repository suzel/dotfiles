# Obsidian

- I also edit in Obsidian, which rewrites files: re-read a file right before changing it.
- Rename, move and delete files with the `obsidian` CLI, not `mv` or `rm`.
- Follow the vault's existing structure, naming, tags and link format.
- Use a plugin's syntax only if `.obsidian/core-plugins.json` or `community-plugins.json`
  enables it.
- Time-ordered flows are Mermaid diagrams in a note, not canvases: Obsidian lays them out.

## Canvas

- When the subject is software, draw canvases like professional software architecture diagrams.
- Edge labels are one to three words.
- Connected nodes share a row or column and edges join their facing sides, so edges are straight
  and cross nothing. When two nodes connect both ways, the edges use different sides or they
  overlap.
- At least 100px between nodes, 200px where the edge label is over one word or the edge crosses
  a group border: short edges hide labels, and a group's label sits above its top-left corner.
  Groups have 40px padding. Coordinates and sizes are multiples of 20.
- Height: about 25px per line plus 30px, a heading counting as two lines.
- When editing, keep existing nodes where they are: I place them by hand.
- After writing, parse the JSON and check that IDs are unique and in Obsidian's format, edges
  point to existing nodes, groups come before and contain their children, nodes don't overlap
  and line breaks in text aren't double-escaped.
- Draw arrows as professional diagrams do: they show the direction things flow.
- Use semantic colors as professional diagrams do: few, consistent and meaningful.
- Add a legend when colors carry meaning.
- The main flow reads in one direction: left to right or top to bottom.
- Keep one level of detail per canvas; link to another canvas for more.
- Nodes of the same kind share a size and a naming style.

## Bases

- After writing, check each changed view with `obsidian base:query`.
