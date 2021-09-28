//
//  TruncateDraw.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/25.
//

import Foundation
import UIKit

class TruncateDraw: UIView {
    var dataSouce: NSMutableAttributedString {
        let str = NSMutableAttributedString(string: "测试 \n这是第二行， 第二行的长度非常非常非常的长 ")
        str.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(location: 12, length: 2))
        return str
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let graphicContext = UIGraphicsGetCurrentContext() else {return}
        graphicContext.textMatrix = CGAffineTransform.identity; //设置
        graphicContext.translateBy(x: 0, y: self.bounds.size.height); //将坐标原点改为(0，height)
        graphicContext.scaleBy(x: 1.0, y: -1.0); //将y轴坐标轴翻转
        
        truncate(rect: rect, context: graphicContext)
    }
    private func truncate(rect: CGRect, context: CGContext) {
        let layoutFrame = generateCTFrame(rect: rect)
        
        let lines = CTFrameGetLines(layoutFrame)
        let numberOfLines = CFArrayGetCount(lines)
        var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: numberOfLines)
        CTFrameGetLineOrigins(layoutFrame, CFRangeMake(0, 0), &lineOrigins)
        for index in 0..<numberOfLines {
            let origin = lineOrigins[index]
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, index), to: CTLine.self)
            let lineRange = CTLineGetStringRange(line)
            if index == numberOfLines - 1,
                  lineRange.location + lineRange.length < dataSouce.length { //绘制截断
                 //1.创建截断标识符
                let truncatePosition = lineRange.location + lineRange.length - 1
                let tokenAttr = dataSouce.attributes(at: truncatePosition, effectiveRange: nil) //将原有的属性也覆盖到截断符上。
                let tokenStr = NSAttributedString(string: "\u{2026}", attributes: tokenAttr)
                
                //2.生成截断符的ctline
                let maxNum = CGFloat.greatestFiniteMagnitude
                let tokenSize = tokenStr.boundingRect(with: CGSize(width: maxNum, height:maxNum ), options: [.usesLineFragmentOrigin], context: nil).size
                let cfStr = unsafeBitCast(tokenStr, to: CFAttributedString.self)
                let trunTokenLine = CTLineCreateWithAttributedString(cfStr) //没看到实际效果
                
                //3.计算剩余的字符长度。
                let lineWidth = rect.size.width - origin.x //每一行的长度
                let truncateEndIndex = CTLineGetStringIndexForPosition(line, CGPoint(x: lineWidth - tokenSize.width, y: 0))
                let restLength = lineRange.location + lineRange.length - truncateEndIndex //剩余的行长度
                //原始的lineStr 并删除不需要的内容。
                guard let originLineStr = dataSouce.attributedSubstring(from: NSRange(location: lineRange.location, length: lineRange.length)).mutableCopy() as? NSMutableAttributedString
                else {continue}
                if restLength < originLineStr.length  { //
                    originLineStr.deleteCharacters(in: NSRange(location: originLineStr.length - restLength, length: restLength))
                    originLineStr.append(tokenStr)
                }
                
                //4.创建有截断的line
                let cfTrStr = unsafeBitCast(originLineStr, to: CFAttributedString.self)
                let truncationLine = CTLineCreateWithAttributedString(cfTrStr)
                let lastLine = CTLineCreateTruncatedLine(truncationLine, rect.width, .end, trunTokenLine)
                LineDraw(position: lineOrigins[numberOfLines-1], context: context, line: lastLine)
            } else {
                LineDraw(position: lineOrigins[index], context: context, line: line)
            }
        }
        
    }
    
    private func LineDraw(position: CGPoint, context: CGContext, line: CTLine?) {
        guard let line = line else {return}
        context.textPosition = position
        CTLineDraw(line, context)
    }
    
    
    private func generateCTFrame(rect: CGRect) -> CTFrame {
        let path = CGMutablePath()
        path.addRect(rect)
        let storage = CTFramesetterCreateWithAttributedString(dataSouce)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, dataSouce.length), path, nil)
        return layoutFrame
    }
}
