//
//  SettingsSliderView.swift
//  SwiftAA
//
//  Created by Kihron on 2/27/24.
//

import SwiftUI

struct SettingsSliderView: View {
    var title: String
    var leftIcon: String
    var rightIcon: String

    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double

    var body: some View {
        HStack {
            Text(title)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                .animation(.smooth, value: title)

            HStack {
                Image(systemName: leftIcon)

                Slider(value: $value, in: range, step: step)

                Image(systemName: rightIcon)
            }
        }
    }
}

#Preview {
    SettingsSliderView(
        title: "Speed", leftIcon: "", rightIcon: "", value: .constant(0), range: 30...120, step: 30)
}
