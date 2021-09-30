//
//  ClickText.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/28.
//

import Foundation
import UIKit
class ClickText: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let graphicContext = UIGraphicsGetCurrentContext() else {return}
        graphicContext.textMatrix = CGAffineTransform.identity; //设置
        graphicContext.translateBy(x: 0, y: self.bounds.size.height); //将坐标原点改为(0，height)
        graphicContext.scaleBy(x: 1.0, y: -1.0); //将y轴坐标轴翻转
       
    }
    
   
}


class CoreTextUtil {
    //通过point 计算 range
    static func convert(point: CGPoint, ctFrame: CTFrame) -> Int {
        let drawRect = CTFrameGetPath(ctFrame)
        let drawHeight = drawRect.boundingBox.size.height
        
        let lineArr = CTFrameGetLines(ctFrame)
        let numberOfLines = CFArrayGetCount(lineArr)
        for index in 0..<numberOfLines {
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lineArr, index), to: CTLine.self)
            var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: numberOfLines)
            CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), &lineOrigins)
            var lineFrag = TextLine()
            let lineWidth = CTLineGetTypographicBounds(line, &(lineFrag.ascent), &(lineFrag.descent), &(lineFrag.leading))
            let lineFrame = CGRect(x: lineOrigins[index].x, y: drawHeight - lineOrigins[index].y - lineFrag.ascent, width: lineWidth, height: lineFrag.ascent + lineFrag.descent + lineFrag.leading)
            let adjustPoint = CGPoint(x: point.x - lineFrame.minX,y: point.y)
            if lineFrame.contains(adjustPoint) {
                return  CTLineGetStringIndexForPosition(line, adjustPoint) //有半个误差长度。
            }
        }
        return -1
    }
}
