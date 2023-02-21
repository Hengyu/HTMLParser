//
//  MIT License
//
//  Created by hengyu on 2021/1/7.
//  Copyright © 2022 hengyu. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import libxml2

public enum HTMLNodeType {
    case href
    case text
    case unknown
    case code
    case span
    case paragraph
    case list
    case unorderedList
    case image
    case orderedList
    case strong
    case preformatted
    case blockquote
}

public final class HTMLNode {

    private var node: xmlNode { nodePtr.pointee }
    private let nodePtr: xmlNodePtr

    public var firstChild: HTMLNode? {
        guard let childNode = node.children else { return nil }
        return HTMLNode(nodePtr: childNode)
    }

    public var content: String? {
        node.children?.pointee.content.map { String(cString: $0) }
    }

    public var allContent: String? {
        let content = xmlNodeGetContent(nodePtr)
        defer { content?.deallocate() }

        return content.map { String(cString: $0) }
    }

    public var htmlContent: String? {
        let buffer = xmlBufferCreateSize(1000)
        let outputBuffer = xmlOutputBufferCreateBuffer(buffer, nil)

        defer {
            xmlOutputBufferClose(outputBuffer)
            xmlBufferFree(buffer)
        }

        htmlNodeDumpOutput(
            outputBuffer,
            node.doc,
            nodePtr,
            UnsafeRawPointer(node.doc.pointee.encoding)?.assumingMemoryBound(to: Int8.self)
        )
        xmlOutputBufferFlush(outputBuffer)

        return buffer?.pointee.content.map { String(cString: $0) }
    }

    public var next: HTMLNode? {
        if let nextPtr = nodePtr.pointee.next {
            return HTMLNode(nodePtr: nextPtr)
        } else {
            return nil
        }
    }

    public var previous: HTMLNode? {
        if let previousPtr = nodePtr.pointee.prev {
            return HTMLNode(nodePtr: previousPtr)
        } else {
            return nil
        }
    }

    public var parent: HTMLNode? {
        if let parentPtr = node.parent {
            return HTMLNode(nodePtr: parentPtr)
        } else {
            return nil
        }
    }

    public var className: String? {
        getValue(forAttribute: "class")
    }

    public var tagName: String? {
        get {
            guard let name = nodePtr.pointee.name else { return nil }
            return String(cString: name)
        }
        set {
            if let newValue {
                xmlNodeSetName(nodePtr, newValue)
            }
        }
    }

    public var children: [HTMLNode] {
        var currentPointer: xmlNodePtr? = node.children
        var array: [HTMLNode] = []

        while let pointer = currentPointer {
            let node = HTMLNode(nodePtr: pointer)
            array.append(node)
            currentPointer = pointer.pointee.next
        }

        return array
    }

    internal init(nodePtr: xmlNodePtr) {
        self.nodePtr = nodePtr
    }

    public func findChild(ofClass className: String) -> HTMLNode? {
        node.children.flatMap {
            HTMLNode.findChild(withAttribute: "class", matchingName: className, in: $0, allowsPartial: false)
        }
    }

    public func findChildren(ofClass className: String) -> [HTMLNode] {
        findChildren(withAttribute: "class", matchingName: className, allowsPartial: false)
    }

    public func findChild(
        withAttribute attribute: String,
        matchingName name: String,
        allowsPartial: Bool
    ) -> HTMLNode? {
        HTMLNode.findChild(withAttribute: attribute, matchingName: name, in: nodePtr, allowsPartial: allowsPartial)
    }

    public func findChildren(
        withAttribute attribute: String,
        matchingName name: String,
        allowsPartial: Bool
    ) -> [HTMLNode] {
        guard let childPtr = node.children else { return [] }

        var nodes: [HTMLNode] = []
        HTMLNode.findChildren(
            withAttribute: attribute,
            matchingName: name,
            in: childPtr,
            allowsPartial: allowsPartial,
            using: &nodes
        )

        return nodes
    }

    public func findChild(withTag tag: String) -> HTMLNode? {
        guard let childNode = node.children else { return nil }

        return HTMLNode.findChild(withTag: tag, in: childNode)
    }

    public func findChildren(withTag tag: String) -> [HTMLNode] {
        guard let childPtr = node.children else { return [] }

        var nodes: [HTMLNode] = []
        HTMLNode.findChildren(withTag: tag, in: childPtr, using: &nodes)
        return nodes
    }

    public func removeChild(_ child: HTMLNode) {
        xmlUnlinkNode(child.nodePtr)
        xmlFree(child.nodePtr)
    }

    public func addChild(_ child: HTMLNode) {
        xmlUnlinkNode(child.nodePtr)
        xmlAddChild(nodePtr, child.nodePtr)
    }

    internal static func getValue(forAttribute attribute: String, in nodePointer: xmlNodePtr) -> String? {
        guard let unwrapped = nodePointer.pointee.properties?.pointee else { return nil }

        var attr: xmlAttr? = unwrapped

        while let attrValue = attr {
            if let attrName = attrValue.name, String(cString: attrName) == attribute {
                if let childNode = attrValue.children?.pointee, let childNodeContent = childNode.content {
                    return String(cString: childNodeContent)
                }
                break
            }
            attr = attrValue.next?.pointee
        }

        return nil
    }

    internal static func setValue(_ newValue: String?, forAttribute attribute: String, in nodePointer: xmlNodePtr) {
        if let newValue {
            xmlSetProp(nodePointer, attribute, newValue)
        } else {
            xmlUnsetProp(nodePointer, attribute)
        }
    }

    internal static func findChild(
        withAttribute attribute: String,
        matchingName name: String,
        in nodePointer: xmlNodePtr,
        allowsPartial: Bool
    ) -> HTMLNode? {
        var currentPointer: xmlNodePtr? = nodePointer

        while let pointer = currentPointer {
            var attr: xmlAttr? = pointer.pointee.properties?.pointee
            while let attrValue = attr {
                if let attrName = attrValue.name, String(cString: attrName) == attribute {
                    var childNode = attr?.children?.pointee
                    while let childNodeValue = childNode {
                        if let contentValue = childNodeValue.content {
                            let matched = !allowsPartial && String(cString: contentValue) == name
                            let matched2 = allowsPartial && String(cString: contentValue).contains(name)
                            if matched || matched2 {
                                return HTMLNode(nodePtr: pointer)
                            }
                        }
                        childNode = childNodeValue.next?.pointee
                    }
                    break
                }
                attr = attrValue.next?.pointee
            }

            if let childNode = pointer.pointee.children,
               let childResult = findChild(
                withAttribute: attribute,
                matchingName: name,
                in: childNode,
                allowsPartial: allowsPartial
               ) {
                return childResult
            }

            currentPointer = pointer.pointee.next
        }

        return nil
    }

    internal static func findChildren(
        withAttribute attribute: String,
        matchingName name: String,
        in nodePointer: xmlNodePtr,
        allowsPartial: Bool,
        using results: inout [HTMLNode]
    ) {
        var currentPointer: xmlNodePtr? = nodePointer

        while let pointer = currentPointer {
            var attr: xmlAttr? = pointer.pointee.properties?.pointee
            while let attrValue = attr {
                if let attrName = attrValue.name?.pointee, attrName == u_char(attribute) {
                    var childNode = attr?.children?.pointee
                    while let childNodeValue = childNode {
                        if let contentValue = childNodeValue.content {
                            let matched = !allowsPartial && String(cString: contentValue) == name
                            let matched2 = allowsPartial && String(cString: contentValue).contains(name)
                            if matched || matched2 {
                                results.append(HTMLNode(nodePtr: pointer))
                            }
                        }
                        childNode = childNodeValue.next?.pointee
                    }
                    break
                }
                attr = attrValue.next?.pointee
            }

            if let childNode = pointer.pointee.children {
                findChildren(
                    withAttribute: attribute,
                    matchingName: name,
                    in: childNode,
                    allowsPartial: allowsPartial,
                    using: &results
                )
            }

            currentPointer = pointer.pointee.next
        }
    }

    internal static func findChild(withTag tag: String, in nodePointer: xmlNodePtr) -> HTMLNode? {
        var currentPointer: xmlNodePtr? = nodePointer

        while let pointer = currentPointer {
            if let name = pointer.pointee.name, String(cString: name) == tag {
                return HTMLNode(nodePtr: pointer)
            }

            if let childNode = pointer.pointee.children,
               let childResult = findChild(withTag: tag, in: childNode) {
                return childResult
            }

            currentPointer = pointer.pointee.next
        }

        return nil
    }

    internal static func findChildren(
        withTag tag: String,
        in nodePointer: xmlNodePtr,
        using results: inout [HTMLNode]
    ) {
        var currentPointer: xmlNodePtr? = nodePointer

        while let pointer = currentPointer {
            if let name = pointer.pointee.name, String(cString: name) == tag {
                results.append(HTMLNode(nodePtr: pointer))
            }
            if let child = pointer.pointee.children {
                findChildren(withTag: tag, in: child, using: &results)
            }

            currentPointer = pointer.pointee.next
        }
    }
}

extension HTMLNode {

    public var type: HTMLNodeType {
        guard let cname = node.name else { return .unknown }

        let name = String(cString: cname)
        switch name {
        case "a": return .href
        case "text": return .text
        case "code": return .code
        case "span": return .span
        case "p": return .paragraph
        case "ul": return .unorderedList
        case "li": return .list
        case "image": return .image
        case "ol": return .orderedList
        case "strong": return .strong
        case "pre": return .preformatted
        case "blockquote": return .blockquote
        default: return .unknown
        }
    }

    public subscript(attribute: String) -> String? {
        get { getValue(forAttribute: attribute) }
        set(newValue) { setValue(newValue, forAttribute: attribute) }
    }

    public func getValue(forAttribute attribute: String) -> String? {
        HTMLNode.getValue(forAttribute: attribute, in: nodePtr)
    }

    public func setValue(_ newValue: String?, forAttribute attribute: String) {
        HTMLNode.setValue(newValue, forAttribute: attribute, in: nodePtr)
    }

    public var toXML: String? {
        let buffer = xmlBufferCreate()
        defer { xmlBufferFree(buffer) }

        xmlNodeDump(buffer, node.doc, nodePtr, 0, 0)
        return buffer?.pointee.content.map { String(cString: $0) }
    }

    public var toHTML: String? {
        let buffer = xmlBufferCreate()
        defer { xmlBufferFree(buffer) }
        htmlNodeDump(buffer, node.doc, nodePtr)
        return buffer?.pointee.content.map { String(cString: $0) }
    }
}
