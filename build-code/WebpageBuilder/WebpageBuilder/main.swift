//
//  main.swift
//  WebpageBuilder
//
//  Created by Frank Schäfer on 21.06.25.
//

import Foundation
import CoreXLSX


// Program to generate a webpage from several templates and a Excel language file.
// The program expects a directory with html templates and an Excel file with translations.

// Structure: [key: [lang: translation]]
var translations: [String: [String: String]] = [:]

do {
    guard let file = XLSXFile(filepath: "language.xlsx") else {
        throw NSError(domain: "FileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open language.xlsx"])
    }
    guard let sharedStrings = try file.parseSharedStrings() else {
        throw NSError(domain: "FileError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not parse shared strings"])
    }
    var translations: [String: [String: String]] = [:]
    for wbk in try file.parseWorkbooks() {
        for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
            let ws = try file.parseWorksheet(at: path)
            let rows = ws.data?.rows ?? []
            guard let headerRow = rows.first else { continue }
            let headers = headerRow.cells.compactMap { $0.stringValue(sharedStrings) }
            for row in rows.dropFirst() {
                let cells = row.cells.compactMap { $0.stringValue(sharedStrings) }
                guard cells.count == headers.count else { continue }
                let key = cells[0]
                var langDict: [String: String] = [:]
                for (i, lang) in headers.enumerated() where i > 0 {
                    langDict[lang] = cells[i]
                }
                translations[key] = langDict
            }
        }
    }
    
    let templatesDir = "templates"
    let fileManager = FileManager.default
    let templateFiles = try fileManager.contentsOfDirectory(atPath: templatesDir)
        .filter { $0.hasSuffix(".html") }
    let languages = translations.values.flatMap { $0.keys }.uniqued()

    for lang in languages {
        let outputDir = "../dist/\(lang)"
        try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
        for templateFile in templateFiles {
            let templatePath = "\(templatesDir)/\(templateFile)"
            let html = try String(contentsOfFile: templatePath, encoding: .utf8)
            let replaced = html.replacingOccurrences(
                of: #"\{\{([\w\-]+)\}\}"#,
                with: { (match: [String]) in
                    let key = match[1]
                    if let value = translations[key]?[lang] {
                        return value
                    } else {
                        print("Missing key: \(key) for language: \(lang)")
                        return "{{\(key)}}"
                    }
                },
                options: [],
                range: nil
            )
            let outputPath = "\(outputDir)/\(templateFile)"
            try replaced.write(toFile: outputPath, atomically: true, encoding: .utf8)
        }
    }
} catch {
    print("Error: \(error)")
    exit(1)
}

// Helper extension for unique elements
extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

// Helper for regex replacement with closure
extension String {
    func replacingOccurrences(
        of pattern: String,
        with replacer: ([String]) -> String,
        options: NSRegularExpression.Options = [],
        range searchRange: Range<String.Index>? = nil
    ) -> String {
        let searchRange = searchRange ?? startIndex..<endIndex
        let nsRange = NSRange(searchRange, in: self)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: nsRange)
        var newString = self
        for result in results.reversed() {
            var groups: [String] = []
            for i in 0..<result.numberOfRanges {
                let range = result.range(at: i)
                if range.location != NSNotFound {
                    groups.append(nsString.substring(with: range))
                }
            }
            let replacement = replacer(groups)
            let range = result.range(at: 0)
            let start = newString.index(newString.startIndex, offsetBy: range.location)
            let end = newString.index(start, offsetBy: range.length)
            newString.replaceSubrange(start..<end, with: replacement)
        }
        return newString
    }
}


