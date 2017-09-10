//
//  Extensions.swift
//  Ysoftware
//
//  Created by Ярослав Ерохин on 15.02.17.
//  Copyright © 2017 Yaroslav Erohin. All rights reserved.
//

import Foundation
import UIKit

public extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array( Set(self) )
    }
}

extension UIView {
    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
}

extension Collection {
    func chunked(by distance: IndexDistance) -> [[SubSequence.Iterator.Element]] {
        var index = startIndex
        let iterator: AnyIterator<Array<SubSequence.Iterator.Element>> = AnyIterator {
            defer {
                index = self.index(index, offsetBy: distance, limitedBy: self.endIndex) ?? self.endIndex
            }
            
            let newIndex = self.index(index, offsetBy: distance, limitedBy: self.endIndex) ?? self.endIndex
            let range = index ..< newIndex
            return index != self.endIndex ? Array(self[range]) : nil
        }
        
        return Array(iterator)
    }
}

public extension Sequence where Iterator.Element: Equatable {
    var uniqueElements: [Iterator.Element] {
        return self.reduce([]){
            uniqueElements, element in

            uniqueElements.contains(element)
                ? uniqueElements
                : uniqueElements + [element]
        }
    }
}

extension UIView {
    func setBackground(withName: String){
        UIGraphicsBeginImageContext(self.frame.size)
        UIImage(named: withName)?.draw(in: self.bounds)
        guard let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() else { return }
        UIGraphicsEndImageContext()
        self.backgroundColor = UIColor(patternImage: image)
    }
}

extension Date {
    struct Formatter { // time for Firebase
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.timeZone = TimeZone(abbreviation: "GMT")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter
        }()
    }

    static func from(iso8601 string:String?) -> Date? {
        if let string_ = string {
            return Formatter.iso8601.date(from: string_)
        }
        return nil
    }

    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }

    /// returns current date as string in iso8601 format
    static var nowTimestamp: String {
        return Formatter.iso8601.string(from: Date())
    }
}

extension String {
    func removing(charactersOf string: String) -> String {
        let characterSet = CharacterSet(charactersIn: string)
        let components = self.components(separatedBy: characterSet)
        return components.joined(separator: "")
    }

    var dateFromISO8601: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }

    var uppercaseFirst: String {
        return String(characters.prefix(1)).uppercased() + String(characters.dropFirst())
    }
}

extension UIView {
    @discardableResult
    func fromNib<T : UIView>() -> T? {
        guard let view = Bundle.main.loadNibNamed(String(describing: type(of: self)),
                                                  owner: self, options: nil)?[0] as? T else { return nil }
        self.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        return view
    }
}

extension UITableView {
    func register(cellNamed name: String) {
        register(UINib(nibName: name, bundle: nil), forCellReuseIdentifier: name)
    }
}

extension UICollectionView {
    func register(cellNamed name: String) {
        register(UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: name)
    }
}

extension UIViewController {
    /// create alert controller
    func alert(_ message:String = "") {
        let string = message
        let alert = UIAlertController(title: "Внимание!", message: string, preferredStyle: .alert)
        let action = UIAlertAction(title: "ОК", style: .default) { _ in alert.dismiss(animated: true) }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    func ask(_ title: String = "Внимание!", question:String, waitFor completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: title, message: question, preferredStyle: .alert)
        let yes = UIAlertAction(title: "Да", style: .default) { _ in completion(true); alert.dismiss(animated: true) }
        let no = UIAlertAction(title: "Нет", style: .default) { _ in completion(false); alert.dismiss(animated: true) }
        alert.addAction(yes)
        alert.addAction(no)
        present(alert, animated: true, completion: nil)
    }

    func dismiss(animated:Bool = false) {
        if let nav = self.navigationController {
            nav.dismiss(animated: animated, completion: nil)
        }
        else {
            dismiss(animated: animated, completion: nil)
        }
    }
}

extension UIViewController {
    func embedInNavigationController() -> UINavigationController {
        return UINavigationController(rootViewController: self)
    }
}

@IBDesignable class RoundedView: UIView {
    @IBInspectable var isRelativeRadius:Bool = true { didSet { setNeedsLayout() } }
    @IBInspectable var cornerRadius:CGFloat = 0.5  { didSet { setNeedsLayout() } }
    @IBInspectable var borderWidth:CGFloat = 0  { didSet { setNeedsLayout() } }
    @IBInspectable var borderColor:UIColor = .clear  { didSet { setNeedsLayout() } }

    override func layoutSubviews() {
        super.layoutSubviews()

        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = isRelativeRadius ? frame.height * cornerRadius : cornerRadius

        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
}

final class RoundedImageView: UIImageView {
    var isRelativeRadius:Bool = false  { didSet { setNeedsLayout() } }
    var cornerRadius:CGFloat = 0  { didSet { setNeedsLayout() } }

    override func layoutSubviews() {
        super.layoutSubviews()

        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = isRelativeRadius ? frame.height * cornerRadius : cornerRadius
    }
}

final class IntrinsicTableView: UITableView {
    override var contentSize:CGSize { didSet { invalidateIntrinsicContentSize() }}
    override var intrinsicContentSize:CGSize {
        layoutIfNeeded()
        return CGSize(width: UIViewNoIntrinsicMetric, height: contentSize.height)
    }
}

func print(_ message:String, from object:AnyObject?) {
    #if DEBUG
        if let object_ = object {
            NSLog("\(object_): \(message)")
        }
        else {
            NSLog(message)
        }
    #endif
}


