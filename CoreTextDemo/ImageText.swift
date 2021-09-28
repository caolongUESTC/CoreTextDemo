//
//  ImageText.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/24.
//

import Foundation
import UIKit

class ImageText: UIView {
    var imgName: String = "homeIcon"
    static let imageFont: UIFont = UIFont.systemFont(ofSize: 15)
    static let textImageHeight: CGFloat = imageFont.lineHeight
    static let textImageWidth: CGFloat = textImageHeight * 2
    lazy var dataSouce: NSMutableAttributedString = {
        let att = NSMutableAttributedString(string: "这是一个简单\n的测试页面")
        att.addAttribute(NSAttributedString.Key.font, value: ImageText.imageFont, range: NSRange(location: 0, length: att.length))
        att.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.blue.cgColor, range: NSRange(location: 0, length: 1))
        return att
    }()
    
    lazy var textImg: UIImage = {
        let img = UIImage(named: imgName) ?? UIImage()
        return img
    }()
    
    func generateCallBack() -> CTRunDelegateCallbacks {
        let  ctRunCallback =  CTRunDelegateCallbacks(version: kCTRunDelegateVersion1,
                                                     dealloc:{ (refCon) -> Void in},
                                                     getAscent: { ( refCon) -> CGFloat in return ImageText.textImageHeight + ImageText.imageFont.descender},
                                                     getDescent: { (refCon) -> CGFloat in return -ImageText.imageFont.descender
            }){ (refCon) -> CGFloat in
                return ImageText.textImageWidth
            }
        return ctRunCallback
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let graphicContext = UIGraphicsGetCurrentContext() else {return}
        graphicContext.textMatrix = CGAffineTransform.identity; //设置
        graphicContext.translateBy(x: 0, y: self.bounds.size.height); //将坐标原点改为(0，height)
        graphicContext.scaleBy(x: 1.0, y: -1.0); //将y轴坐标轴翻转
        
        //ctFrame绘制
       imageTextDraw(rect, context: graphicContext)
       
    }
    
    private func imageTextDraw(_ rect: CGRect, context: CGContext) {
        let path = CGMutablePath()
        path.addRect(rect)
        dataSouce.insert(generateImageStr(), at: 2) //可以写入任意位置
        let storage = CTFramesetterCreateWithAttributedString(dataSouce)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, dataSouce.length), path, nil)
       
        CTFrameDraw(layoutFrame, context)
        
        drawImageInText(layoutFrame: layoutFrame, context: context)
    }
    //将image绘制出来
    private func drawImageInText(layoutFrame: CTFrame, context: CGContext) {
        // 1.获得CTLine数组
        let lines = CTFrameGetLines(layoutFrame)
        // 2.获得行数
        let numberOfLines = CFArrayGetCount(lines)
        // 3.获得每一行的origin, CoreText的origin是在字形的baseLine处的, 请参考字形图
        var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: numberOfLines)
        CTFrameGetLineOrigins(layoutFrame, CFRangeMake(0, 0), &lineOrigins)
        //绘制line
        for (index, point) in lineOrigins.enumerated() {
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, index), to: CTLine.self)
            var lineAscent = CGFloat()
            var lineDescent = CGFloat()
            var lineLeading = CGFloat() //不需要用到
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading)
    
            let runs = CTLineGetGlyphRuns(line)
            let runCount = CFArrayGetCount(runs) //当前行的runs
            for index in 0..<runCount {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, index), to: CTRun.self)
                let ctAttributes = CTRunGetAttributes(run) as NSDictionary
                let pictureName = ctAttributes.object(forKey: "imgName")
                
                guard pictureName != nil else {continue} //只有图片才会进行绘制
                var runAscent = CGFloat()
                var runDescent = CGFloat()
                var runLeading = CGFloat()
                let imgWidth = CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &runAscent, &runDescent, &runLeading)
                let imgOffsetX = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
                let imgRect = CGRect(x: point.x + imgOffsetX, y: point.y - runDescent, width: imgWidth, height: runAscent + runDescent + runLeading)
                if let picName = pictureName as? String {
                    let image = UIImage(named: picName)
                    guard let bitmap = image?.cgImage else {return}
                    context.draw(bitmap, in: imgRect)
                }
            }
           
        }
        
    }
    //原始方式
    private func generateImageStr() -> NSMutableAttributedString {
        var runCallBack = generateCallBack()
        let runDelegate = CTRunDelegateCreate(&runCallBack, nil)
        let imgStr = NSMutableAttributedString(string: " ")
        imgStr.addAttribute(kCTRunDelegateAttributeName as NSAttributedString.Key , value: runDelegate!, range: NSRange(location: 0, length: 1) )
        imgStr.addAttribute(NSAttributedString.Key(rawValue: "imgName"), value: imgName, range: NSRange(location: 0, length: 1))
        //用于处理一个当有多个图片同时放置到一行的情况。需要通过imgName进行区分
        return imgStr
    }
}
