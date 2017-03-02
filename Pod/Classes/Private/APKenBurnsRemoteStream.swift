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

    var imageUrls: [URL] = [] {
        didSet {
            self.images = [UIImage?](count: self.imageUrls.count, repeatedValue: nil)
            self.initiateDownloads()
        }
    }
    
    fileprivate var images: [UIImage?] = []
    fileprivate let currentIndex = 0
    
    fileprivate func nextImage(forKenBurnsView: APKenBurnsView) -> UIImage? {
        if let nextImage = self.images[currentIndex] {
            return nextImage
        }
        
        currentIndex += 1
        return nil
    }
    
    fileprivate func initiateDownloads() {
        for (index, url) in imageUrls.enumerated() {
            ImageLoader.loadImage(withURL: url.url, completion: { (image) in
                self.images[index] = image
            })
        }
    }
}
