//
//  CTImageView.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/28.
//

import UIKit

//在类名的上方，添加两个浮点类型的全局变量，表示在富文本中插入的图片等尺寸。
let picWidth = CGFloat(200.0)
let picHeight = CGFloat(133.0)

class CTImageView: UIView
{
    
    lazy var mutableStr: NSMutableAttributedString = {
        //创建一个字符串常量，表示富文本的内容。
        //图片将被插入到字符串的两个换行符之间的位置。
        let article = "Coffee is a brewed drink prepared from roasted coffee beans, which are the seeds of berries from the Coffea plant.\n\nThe genus Coffea is native to tropical Africa, and Madagascar, the Comoros, Mauritius and Réunion in the Indian Ocean."
        //通过一个字符串常量，创建一个富文本字符串。
        let attributedStr = NSMutableAttributedString(string: article)
        return attributedStr
    }()
    
    
    private func genenrateCallBack() ->  CTRunDelegateCallbacks {
        let  ctRunCallback =  CTRunDelegateCallbacks(version: kCTRunDelegateVersion1,
                                                     dealloc:{ (refCon) -> Void in},
                                                     getAscent: { ( refCon) -> CGFloat in return picHeight},
                                                     getDescent: { (refCon) -> CGFloat in return 0
            }){ (refCon) -> CGFloat in
                return picWidth
            }
        return ctRunCallback
    }
    
    private func generateImageStr() -> NSMutableAttributedString {
        
        //获得图片占位符的尺寸信息，
        //该方法依次设置了，占位符的基线至占位符顶部的距离，
        //基线至占位符底部的距离，和占位符宽度三个尺寸的数据。
        var ctRunCallback = genenrateCallBack()

        //初始化一个字符串变量，设置待插入的图片在项目文件夹中的名称。
        var picture = "homeIcon"
        //创建一个代理对象，作为占位符的代理属性。
        let ctRunDelegate  = CTRunDelegateCreate(&ctRunCallback, &picture)
        //创建一个可变属性的字符串对象，作为待插入图片的占位符，
        //它的内容就是一个简单的空格
        let placeHolder = NSMutableAttributedString(string: " ")

        //设置占位符属性的值，这样当绘制图片时，可以从该属性中，获得待绘制图片的位置和尺寸信息。
        placeHolder.addAttribute(kCTRunDelegateAttributeName as NSAttributedString.Key,
                                 value: ctRunDelegate!, range: NSMakeRange(0, 1))
        //继续给占位符添加一个自定义的属性，并设置属性的值为图片的名称，
        //这样当绘制图片时，可以从该属性中，获得待绘制图片的名称。
        placeHolder.addAttribute(NSAttributedString.Key(rawValue: "pictureName"),
                                 value: picture, range: NSMakeRange(0, 1))
        return placeHolder
    }
    
    
    //实现视图的绘制方法
    override func draw(_ rect: CGRect)
    {
        super.draw(rect)

        //设置填充颜色为橙色
        UIColor.orange.setFill()
        //在视图的显示区域填充橙色
        UIRectFill(rect)
        let placeHolder = generateImageStr()
        
        let attributedStr = mutableStr
        //将图片占位符插入到两个换行符之间的位置。
        attributedStr.insert(placeHolder, at: 115)
        //给富文本添加下划线样式，
        attributedStr.addAttribute(kCTUnderlineStyleAttributeName as NSAttributedString.Key,
                                   value: 1, range: NSRange(location: 0, length: attributedStr.length))

        //通过富文本对象，获得帧设置器，也就是帧的工厂类。
        let framesetter = CTFramesetterCreateWithAttributedString(attributedStr)
        //设置以当前的显示区域，作为绘制的区域。
        let path = UIBezierPath(rect: rect)
        //获得用于绘制的帧对象。
        let ctFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributedStr.length), path.cgPath, nil)

        //在绘制之前，需要指定绘制的图形上下文，在此获得当前的图形上下文。
        let crtContext = UIGraphicsGetCurrentContext()
        //由于两个矿建的坐标系统的原点位置不同，所以需要对上下文进行一些变形操作，
        //首先设置图形上下文的字体矩阵。
        crtContext!.textMatrix = CGAffineTransform.identity
        //然后对图形上下文进行翻转。
        crtContext?.scaleBy(x: 1.0, y: -1.0)
        //再对图形上下文进行平移操作。
        crtContext?.translateBy(x: 0, y: self.bounds.size.height * -1)
        //使用帧绘制函数，将帧对象，绘制在指定的图形上下文中。
        CTFrameDraw(ctFrame, crtContext!)

        drawImageInText(crtContext: crtContext, ctFrame: ctFrame)
    }
    
    //绘制图片的过程
    private func drawImageInText(crtContext: CGContext?, ctFrame: CTFrame) {
        //此时虽然我们还没有在富文本中插入图片，但是富文本已经拥有了标志符，
        //所以在渲染时会自动保留指定的区域，等待图片的渲染。
        //本条语句用来从帧对象中，获得了所有的行对象。
        let ctLines = CTFrameGetLines(ctFrame) as NSArray
        //创建一个坐标点类型的数组，用来存储每一行文字原点的位置。
        var originsOfLines = [CGPoint](repeating: CGPoint.zero, count: ctLines.count)

        //初始化一个范围对象
        let range: CFRange = CFRangeMake(0, 0)
        //设置每一行文字原点的位置
        CTFrameGetLineOrigins(ctFrame, range, &originsOfLines)

        //现在可以进行图片的绘制工作了，由于占位符处于CTRun对象中，
        //所以我们首先通过一个循环语句，对行数组，即6行的文字内容进行遍历。
        for i in 0..<ctLines.count
        {
            //获得当前行的原点位置
            let ctLineOrigin = originsOfLines[i]
            //获得当前行中的所有指定对象的数组
            let ctRuns = CTLineGetGlyphRuns(ctLines[i] as! CTLine) as NSArray

            //通过一个循环语句，对数组进行遍历操作。
            for ctRun in ctRuns
            {
                //获得遍历到的对象的属性字典
                let ctAttributes = CTRunGetAttributes(ctRun as! CTRun) as NSDictionary
                //获得字典中的图片名称属性
                let pictureName = ctAttributes.object(forKey: "pictureName")
                //通过判断图片名称是否为空，来检测当前的对象，是否是插入的那个图片的占位符
                if pictureName != nil
                {
                    //获得遍历到的对象，
                    //在一行中的水平方向上的便宜距离
                    let offset = CTLineGetOffsetForStringIndex(ctLines[i] as! CTLine, CTRunGetStringRange(ctRun as! CTRun).location, nil)
                    //获得待绘制的图片，在水平方向上的位置
                    let picturePosX = ctLineOrigin.x + offset
                    //通过当前行的原点，水平偏移和图片的尺寸信息，
                    //创建一个图片将被绘制的目标区域。
                    let pictureFrame = CGRect(x: picturePosX, y: ctLineOrigin.y, width: picWidth, height: picHeight)
                    //根据获得的图片名称属性，从项目文件夹中，读取指定名称的图片。
                    let image = UIImage(named: pictureName as! String)
                    //最后将图片绘制在指定占位区域。
                    crtContext?.draw((image?.cgImage)!, in: pictureFrame)
                }
            }
        }
        
    }
}
