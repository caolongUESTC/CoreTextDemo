//
//  AsyncText.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/10/14.
//

import Foundation
import UIKit



class AsyncText: UIView {
    let util: AsyncUtil = AsyncUtil()
    var textImage: UIImage?


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let estimateFrame = self.frame.size
        DispatchQueue.global().async {
            let image = self.util.generateImage(estimateFrame)
            DispatchQueue.main.async {
                self.layer.contents = image?.cgImage
            }
        }
    }
}

class AsyncUtil {
    var dataSouce: NSMutableAttributedString {
        var source: String = ""
        for index in 0..<100 {
            source = "\(source)\(index)"
        }
        return NSMutableAttributedString(string: source, attributes: [NSAttributedString.Key.backgroundColor: UIColor.yellow.cgColor])
    }
    
    func generateImage(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        guard let graphicContext = UIGraphicsGetCurrentContext() else {return nil}
        drawText(size: size, str: dataSouce, graphicContext: graphicContext)
        let textImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return textImage
    }
    
    func drawText(size: CGSize, str: NSAttributedString, graphicContext: CGContext)  {
        graphicContext.textMatrix = CGAffineTransform.identity; //设置
        graphicContext.translateBy(x: 0, y: size.height); //将坐标原点改为(0，height)
        graphicContext.scaleBy(x: 1.0, y: -1.0); //将y轴坐标轴翻转
        
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let storage = CTFramesetterCreateWithAttributedString(str)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, str.length), path, nil)
        CTFrameDraw(layoutFrame, graphicContext)
    }
}
