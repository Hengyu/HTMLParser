# HTMLParser

![](https://img.shields.io/badge/iOS-13.0%2B-green)
![](https://img.shields.io/badge/macCatalyst-13.0%2B-green)
![](https://img.shields.io/badge/macOS-10.15%2B-green)
![](https://img.shields.io/badge/Swift-5-orange?logo=Swift&logoColor=white)
![](https://img.shields.io/github/last-commit/hengyu/HTMLParser)

**HTMLParser** is a Swift package built upon [`libxml2`](https://gitlab.gnome.org/GNOME/libxml2) and provides various methods in dealing with HTML strings.

## Table of contents

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [License](#license)

## Requirements

- iOS 13.0+, macCatalyst 13.0+, macOS 10.15+

## Installation

`HTMLParser` could be installed via [Swift Package Manager](https://www.swift.org/package-manager/). Open Xcode and go to **File** -> **Add Packages...**, search `https://github.com/hengyu/HTMLParser.git`, and add the package as one of your project's dependency.

## Usage

```swift
guard
    let parser = HTMLParser(html: htmlString, encoding: encoding),
    let nodes = parser.bodyNode?.findChildren(withTag: "div"),
    !nodes.isEmpty
else { return nil }

nodes.forEach { child in
    // do something
}
```

## License

[HTMLParser](https://github.com/hengyu/HTMLParser) is released under the [MIT License](LICENSE).
