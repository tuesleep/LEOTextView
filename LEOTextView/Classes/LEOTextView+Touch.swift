//
//  LEOTextView+Touch.swift
//  Pods
//
//  Created by Leonardo Hammer on 02/06/2017.
//
//

import Foundation

extension LEOTextView {

  
  open override func touchesShouldBegin(_ touches: Set<UITouch>, with event: UIEvent?, in view: UIView) -> Bool {
    debugPrint("touches should begin")
    //debugPrint("event: \(event)")
    //debugPrint("view: \(view)")
    
    return true
  }
  
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    debugPrint("touches Began")
    
      
//    debugPrint("touches: \(touches)")
  //  debugPrint("event: \(event)")
  }
}
