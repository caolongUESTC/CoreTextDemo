//
//  SimpleDraw.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/24.
//

import Foundation
import UIKit

class SimpleDraw: UIView {
    var dataSouce: NSMutableAttributedString {
        return NSMutableAttributedString(string: "测试 \n这是第二行， 第二行的长度非常非常非常的长 ")
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let graphicContext = UIGraphicsGetCurrentContext() else {return}
        graphicContext.textMatrix = CGAffineTransform.identity; //设置
        graphicContext.translateBy(x: 0, y: self.bounds.size.height); //将坐标原点改为(0，height)
        graphicContext.scaleBy(x: 1.0, y: -1.0); //将y轴坐标轴翻转
        
//        normalDraw(context: graphicContext, rect: rect)
        lineDraw(context: graphicContext, rect: rect)
    }
    
    //正常绘制
    private func normalDraw(context: CGContext, rect: CGRect) {
        //ctFrame绘制
        let path = CGMutablePath()
        path.addRect(rect)
        let storage = CTFramesetterCreateWithAttributedString(dataSouce)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, dataSouce.length), path, nil)
        CTFrameDraw(layoutFrame, context)
    }
    //逐行绘制
    private func lineDraw(context: CGContext, rect: CGRect) {
        let path = CGMutablePath()
        path.addRect(rect)
        let storage = CTFramesetterCreateWithAttributedString(dataSouce)
        let layoutFrame = CTFramesetterCreateFrame(storage, CFRangeMake(0, dataSouce.length), path, nil)
        
        // 1.获得CTLine数组
        let lines = CTFrameGetLines(layoutFrame)
        // 2.获得行数
        let numberOfLines = CFArrayGetCount(lines)
        // 3.获得每一行的origin, CoreText的origin是在字形的baseLine处的, 请参考字形图
        var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: numberOfLines)
        CTFrameGetLineOrigins(layoutFrame, CFRangeMake(0, 0), &lineOrigins)
        // 4.遍历每一行进行绘制
        for index in 0..<numberOfLines {
            let origin = lineOrigins[index]
            // 参考: http://swifter.tips/unsafe/
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, index), to: CTLine.self)
            context.textPosition = origin
            // 开始一行的绘制
            CTLineDraw(line, context)
        }
    }
    
}
