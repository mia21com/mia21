//
//  AppError.swift
//  MiaSwiftUIExample
//
//  Created on November 27, 2025.
//  Copyright © 2025 Mia21. All rights reserved.
//
//  Description:
//  App-wide error model for consistent error handling and alert presentation.
//

import Foundation

struct AppError: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  
  init(title: String = "Error", message: String) {
    self.title = title
    self.message = message
  }
  
  init(title: String = "Error", error: Error) {
    self.title = title
    self.message = error.localizedDescription
  }
  
  static func == (lhs: AppError, rhs: AppError) -> Bool {
    lhs.id == rhs.id
  }
}

