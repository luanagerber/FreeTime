//
//  String+Extensions.swift
//  FreeTime
//
//  Created by Thales Araújo on 02/06/25.
//

extension String {
    var capitalizingFirstLetter: String {
        prefix(1).uppercased() + dropFirst()
    }
}
