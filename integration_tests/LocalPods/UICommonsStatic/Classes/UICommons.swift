
import Foundation

public struct UICommonsStatic {
  private class DummyStatic { }

  public static func jsonString(from fileName: String, fileExtension: String = ".json") -> String? {
    return dataFromFile(fileName, fileExtension: fileExtension)
      .flatMap { String(data: $0, encoding: .utf8) }
  }

  private static func dataFromFile(_ fileName: String, fileExtension: String) -> Data? {
    guard
      let bundlePath = Bundle(for: DummyStatic.self).path(forResource: "UICommonsStatic", ofType: "bundle"),
      let bundle = Bundle(path: bundlePath),
      let pathUrl = bundle.url(forResource: fileName, withExtension: fileExtension),
      let fileData = try? Data(contentsOf: pathUrl)
    else { return nil }
    return fileData
  }
}
