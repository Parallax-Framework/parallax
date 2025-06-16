# Parallax Framework

**Parallax** is a light-weight, modular roleplay framework for Garry's Mod. It's built from the ground up to give roleplay servers the capabilities to create stable, dynamic, and immersive experiences. Parallax prioritizes performance, organization, and total control for developers who wish to avoid both the bloat and legacy issues of other existing frameworks.

No matter if it's a Half-Life universe roleplay, a military server, a city set in the present time, or something else, Parallax offers you the foundation on which to make your vision a reality.

---

## Features

Parallax has a wide array of useful features for developers and server owners alike:

- **Modular Architecture**
  Code is separated into small, independent modules that make it easier to maintain, update, and debug. Each system only does one job, making it easier to extend or replace.

- **Custom UI System**
  A fully customizable user interface system inspired by Valve's Gamepad UI design, allowing developers to build immersive menus and HUDs that match the tone of their server.

- **Inventory System**
  Items are stored based on weight rather than slots. This system allows more realism, as players need to consider the size and weight of what they carry rather than just a fixed number of items.

- **Database Support**
  Built-in support for both SQLite and MySQL. This makes it possible to run development tests offline with SQLite and switch to MySQL for live servers.

- **Secure Networking**
  Parallax includes a custom networking layer that compresses and encrypts data, reducing lag and preventing client-side exploits or sniffing.

- **Schema System**
  Items, factions, classes, and more can be defined through simple Lua files inside your schema. This makes it easy to separate content from the framework and keep things organized.

- **Enforced Code Standards**
  All code is written using K\&R Lua formatting and documented with LDoc, making it easy to read and modify even after a long time.

---

## Installing Parallax

To install Parallax on your server or for local testing, follow these steps carefully:

1. Download or clone the Parallax core framework and place it in your `garrysmod/gamemodes/` folder.
2. Clone or create a schema. The schema folder should be placed in the same `gamemodes/` directory, alongside the core.
3. The schema must include a `gamemode/` directory containing the schema's code and configuration.
4. Make sure both folders are named clearly (e.g., `parallax` for the core and `parallax-skeleton` for your schema).
5. Start Garry's Mod and select the schema from the menu, or set it in your server configuration file for multiplayer hosting.

Example layout:

```
garrysmod/
└── gamemodes/
    ├── parallax/
    └── parallax-skeleton/
```

This setup keeps the framework and your custom content fully separate, making updates and maintenance much easier.

---

## Repositories

Parallax is split across different repositories to keep things clean and organized:

- [`parallax`](https://github.com/Parallax-Framework/parallax): The core of the framework. All essential features and base systems live here.
- [`parallax-skeleton`](https://github.com/Parallax-Framework/parallax-skeleton): A blank schema template for developers to use as a starting point.

> Some repositories may remain private while development continues. Public releases will be announced when ready.

---

## Who Is This For?

Parallax is for developers who require absolute control of server code without the clutter of bloated frameworks and legacy systems. They feature:

- Server owners who want to create immersive and serious RP environments.
- Developers looking for a clean and organized codebase to build on.
- Communities that care about long-term support, updates, and readable code.

Regardless of whether you're a solo developer or a team of developers, Parallax offers a solid foundation for your next project.

---

## Contributing

We welcome community contributions. If you want to help improve Parallax, here's how to begin:

1. Fork the repository and make your changes in a separate branch.
2. Follow the [Parallax style guide](STYLE.md) for formatting and structure.
3. Test your changes in both singleplayer and multiplayer where possible.
4. Add LDoc comments for new functions, modules, or systems.
5. Open a pull request and describe your changes clearly.

We ensure we keep the structure tidy and solid, so quality of code matters. Be patient and read it twice before pushing.

---

## Framework Integrity

In case you identify code which seems to have been copied from another framework or is too similar to other works elsewhere, please inform us. We are committed to originality and would rather not reproduce or borrow other works without proper clearance.

It's crucial for us to create something from scratch, and we'd like everything we employ within Parallax to either be original or properly attributed.

---

## License & Credit Requirements

Parallax is available under [MIT License](LICENSE). It can be modified, used, and distributed freely — subject to certain conditions.

**You must give proper credit** if you utilize any part of this framework. This entails:

- Keeping the license header at the beginning of each original file.
- Including an explicit declaration within your own README or documentation telling users your project is based on the Parallax Framework.
- Avoid presenting another person's framework and how it works as your own.

Overlooking such rules is a violation of license and may result in action against it.

---

## Contact

For questions, help, or to stay updated on development:

- Open an issue or pull request on the GitHub repository
- Join the [community Discord server](https://discord.gg/yekEvSszW3)

<p align="center">
  <img src="https://i.imgur.com/Xw1YITj.png" alt="Centered Image" />
</p>