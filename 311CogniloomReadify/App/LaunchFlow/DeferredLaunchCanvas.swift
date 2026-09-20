//
//  DeferredLaunchCanvas.swift
//

import SwiftUI

struct DeferredLaunchCanvas: View {
    @ObservedObject var state: LaunchStagingState

    private var clampedProgress: Double { min(1.0, max(0.05, state.progress)) }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()

            Image("img_background")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ManuscriptLaunchRuling()
                .opacity(0.10)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 22) {
                    ZStack {
                        Rectangle()
                            .strokeBorder(Color("AppAccent").opacity(0.35), lineWidth: 1)
                            .padding(5)
                        Rectangle()
                            .strokeBorder(Color("AppTextPrimary").opacity(0.22), lineWidth: 1)

                        VStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color("AppTextSecondary").opacity(0.28), lineWidth: 5)
                                    .frame(width: 78, height: 78)

                                Circle()
                                    .trim(from: 0, to: CGFloat(clampedProgress))
                                    .stroke(
                                        Color("AppPrimary"),
                                        style: StrokeStyle(lineWidth: 5, lineCap: .butt)
                                    )
                                    .frame(width: 78, height: 78)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.3), value: clampedProgress)

                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Color("AppPrimary"))
                            }

                            Text("Cogniloom")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color("AppPrimary").opacity(0.55))
                                        .frame(height: 2)
                                        .offset(y: 8)
                                }
                                .padding(.bottom, 10)

                            Text(state.statusMessage)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color("AppTextSecondary"))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.85)
                                .padding(.horizontal, 8)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color("AppTextSecondary").opacity(0.2))
                                        .frame(height: 4)
                                    Rectangle()
                                        .fill(Color("AppAccent"))
                                        .frame(width: geo.size.width * CGFloat(clampedProgress), height: 4)
                                        .animation(.easeInOut(duration: 0.3), value: clampedProgress)
                                }
                            }
                            .frame(height: 4)
                            .padding(.top, 4)

                            Text("\(Int(clampedProgress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .foregroundStyle(Color("AppAccent"))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 32)
                    }
                    .background(Color("AppSurface"))
                    .shadow(color: .black.opacity(0.28), radius: 4, x: 2, y: 3)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ManuscriptLaunchRuling: View {
    var body: some View {
        Canvas { context, size in
            let line = Color("AppTextPrimary")
            var y: CGFloat = 28
            while y < size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(line), lineWidth: 0.6)
                y += 22
            }
            var margin = Path()
            margin.move(to: CGPoint(x: 28, y: 0))
            margin.addLine(to: CGPoint(x: 28, y: size.height))
            context.stroke(margin, with: .color(Color("AppAccent")), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
