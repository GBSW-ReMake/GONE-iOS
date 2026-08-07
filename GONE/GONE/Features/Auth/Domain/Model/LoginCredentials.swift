//
//  LoginCredentials.swift
//  GONE
//
//  Created by Codex on 2026-08-03.
//

import Foundation

struct LoginCredentials: Equatable {
    let identifier: String
    let password: String
    let role: AccountRole
}
