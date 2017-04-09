//
// Created by Erik van der Plas on 3/2/17.
//

class ImageLoader {
    
    class func loadImage(withURL url: URL, completion: @escaping (UIImage) -> Void) {
        
        DispatchQueue(label: "image-loading").async {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let writeURL = documents.appendingPathComponent(url.lastPathComponent ?? url.absoluteString)
            
            if let data = try? Data(contentsOf: URL(fileURLWithPath: writeURL.absoluteString.replacingOccurrences(of: "file://", with: ""))) {
                
                if let image = UIImage(data: data) {
                    
                    completion(image)
                    
                    return
                }
            }
            
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    do {
                        try data.write(to: URL(fileURLWithPath: writeURL.absoluteString.replacingOccurrences(of: "file://", with: "")), options: .atomicWrite)
                    } catch { }
                    
                    completion(image)
                }
            }
        }
    }
}

public class APKenBurnsRemoteStream: APKenBurnsViewDataSource {
    
    public init(initialUrls: [URL]? = nil) {
        if let initialUrls = initialUrls {
            self.imageUrls = initialUrls
        }
    }
    
    public var imageUrls: [URL] = [] {
        didSet {
            self.images = [UIImage?](repeating: nil, count: self.imageUrls.count)
            self.initiateDownloads()
        }
    }
    
    public var proportionalFocusRects: [CGRect] = []
    
    public var images: [UIImage?] = []
    public var currentIndex = 0
    
    public func nextProportionalFocusRect(forKenBurnsView: APKenBurnsView) -> CGRect? {
        if currentIndex >= self.images.count {
            currentIndex = 0
        }
        
        if self.proportionalFocusRects.count > 0 && currentIndex < self.proportionalFocusRects.count {
            return self.proportionalFocusRects[currentIndex]
        }
        
        return nil
    }
    
    public func nextImage(forKenBurnsView: APKenBurnsView) -> UIImage? {
        if self.images.count > 0 {
            if currentIndex >= self.images.count {
                currentIndex = 0
            }
            
            if let nextImage = self.images[currentIndex] {
                currentIndex += 1
                return nextImage
            }
        }
        
        return nil
    }
    
    fileprivate func initiateDownloads() {
        for (index, url) in imageUrls.enumerated() {
            ImageLoader.loadImage(withURL: url, completion: { (image) in
                DispatchQueue.main.async {
                    self.images[index] = image
                }
            })
        }
    }
}
