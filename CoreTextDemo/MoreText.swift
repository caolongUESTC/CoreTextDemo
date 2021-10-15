//
//  MoreText.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/29.
//

import Foundation
import UIKit

class MoreText: UIView {
    var tapMoreBlock: (() -> Void)?
    var tapContentBlcok: (() -> Void)?
    private var drawFrame: CTFrame?
    private var truncateTokenIndex: Int? 
    let moreGaping: CGFloat = 4
    var moreText: NSMutableAttributedString {
        let more = NSMutableAttributedString(string: "更多", attributes: [NSAttributedString.Key.foregroundColor: UIColor.blue.cgColor,
                                                                        NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        return more
    }
    var dataSource: NSMutableAttributedString {
        let str = NSMutableAttributedString(string: "测试\n这是第二行，第二行的长度非常非常非常的长。还有一些其他的数据和内容 ")
        str.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: NSRange(location: 11, length: 2))
        str.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: str.length))
        return str
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
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
                  lineRange.location + lineRange.length < dataSource.length { //绘制截断
                 //1.创建截断标识符
                let truncatePosition = lineRange.location + lineRange.length - 1
                let tokenAttr = dataSource.attributes(at: truncatePosition, effectiveRange: nil) //将原有的属性也覆盖到截断符上。
                let tokenStr = NSAttributedString(string: "\u{2026}", attributes: tokenAttr)
                
                //2.生成截断符的ctline
                let maxNum = CGFloat.greatestFiniteMagnitude
                let tokenSize = tokenStr.boundingRect(with: CGSize(width: maxNum, height:maxNum ), options: [.usesLineFragmentOrigin], context: nil).size
                let moreSize = moreText.boundingRect(with: CGSize(width: maxNum, height: maxNum), options: [.usesLineFragmentOrigin], context: nil).size
                
                //3.计算剩余的字符长度。
                let lineWidth = rect.size.width - origin.x //每一行的长度
                let truncateEndIndex = CTLineGetStringIndexForPosition(line, CGPoint(x: lineWidth - tokenSize.width - moreSize.width - moreGaping, y: 0))
                let restLength = max(lineRange.location + lineRange.length - truncateEndIndex, 0) //剩余的行长度 truncateTokenIndex
                truncateTokenIndex = truncateEndIndex
                //原始的lineStr 并删除不需要的内容。
                guard let originLineStr = dataSource.attributedSubstring(from: NSRange(location: lineRange.location, length: lineRange.length)).mutableCopy() as? NSMutableAttributedString
                else {continue}
                if restLength < originLineStr.length  { //
                    originLineStr.deleteCharacters(in: NSRange(location: originLineStr.length - restLength, length: restLength))
                    originLineStr.append(tokenStr)
                    originLineStr.append(moreText)
                }
                
                //4.创建有截断的line
                let cfTrStr = unsafeBitCast(originLineStr, to: CFAttributedString.self)
                let truncationLine = CTLineCreateWithAttributedString(cfTrStr)
                //测试部分
                let firstLineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
                let truncationWidth = CTLineGetTypographicBounds(truncationLine, nil, nil, nil)
                print ("截断前\(firstLineWidth) 截断后\(truncationWidth)")
                LineDraw(position: lineOrigins[numberOfLines-1], context: context, line: truncationLine)
            } else if index == numberOfLines - 1 {
                truncateTokenIndex = Int.max
                LineDraw(position: lineOrigins[index], context: context, line: line)
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
        let storage = CTFramesetterCreateWithAttributedString(dataSource)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, dataSource.length), path, nil)
        drawFrame = layoutFrame
        return layoutFrame
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let ctframe = drawFrame, let point = touches.first?.location(in: self) else {return}
        let index = CoreTextUtil.convert(point: point, ctFrame: ctframe)
        guard index >= 0, let truncateTokenIndex = truncateTokenIndex else {return} //小于零说明没有找到对应位置
        if index > truncateTokenIndex {
            tapMoreBlock?()
        } else {
            tapContentBlcok?()
        }
    }
}
