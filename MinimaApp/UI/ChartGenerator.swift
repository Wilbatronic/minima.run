import SwiftUI
import Charts

/// "The Artist"
/// Generates charts and diagrams from structured data.
/// Enables "Show me a chart of..." queries.
public class ChartGenerator {
    public static let shared = ChartGenerator()
    
    private init() {}
    
    /// Parse data from LLM response and render a chart
    @MainActor
    public func generateChart(from data: ChartData) -> some View {
        switch data.type {
        case .bar:
            return AnyView(BarChartView(data: data))
        case .line:
            return AnyView(LineChartView(data: data))
        case .pie:
            return AnyView(PieChartView(data: data))
        }
    }
    
    /// Parse chart data from structured text
    public func parseChartData(from text: String) -> ChartData? {
        // Expected format:
        // CHART:bar
        // TITLE:Sales by Region
        // DATA:North=100,South=80,East=120,West=90
        
        let lines = text.components(separatedBy: "\n")
        var type: ChartType = .bar
        var title = "Chart"
        var dataPoints: [ChartDataPoint] = []
        
        for line in lines {
            if line.starts(with: "CHART:") {
                let typeStr = line.replacingOccurrences(of: "CHART:", with: "")
                type = ChartType(rawValue: typeStr) ?? .bar
            } else if line.starts(with: "TITLE:") {
                title = line.replacingOccurrences(of: "TITLE:", with: "")
            } else if line.starts(with: "DATA:") {
                let dataStr = line.replacingOccurrences(of: "DATA:", with: "")
                let pairs = dataStr.components(separatedBy: ",")
                for pair in pairs {
                    let parts = pair.components(separatedBy: "=")
                    if parts.count == 2, let value = Double(parts[1]) {
                        dataPoints.append(ChartDataPoint(label: parts[0], value: value))
                    }
                }
            }
        }
        
        guard !dataPoints.isEmpty else { return nil }
        return ChartData(type: type, title: title, dataPoints: dataPoints)
    }
}

// MARK: - Data Models

public struct ChartData {
    let type: ChartType
    let title: String
    let dataPoints: [ChartDataPoint]
}

public struct ChartDataPoint: Identifiable {
    public let id = UUID()
    let label: String
    let value: Double
}

public enum ChartType: String {
    case bar, line, pie
}

// MARK: - Chart Views

@available(iOS 16.0, macOS 13.0, *)
struct BarChartView: View {
    let data: ChartData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.title)
                .font(.headline)
            
            Chart(data.dataPoints) { point in
                BarMark(
                    x: .value("Category", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .bottom, endPoint: .top))
            }
            .frame(height: 200)
        }
        .padding()
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct LineChartView: View {
    let data: ChartData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.title)
                .font(.headline)
            
            Chart(data.dataPoints) { point in
                LineMark(
                    x: .value("Category", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.purple)
            }
            .frame(height: 200)
        }
        .padding()
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct PieChartView: View {
    let data: ChartData
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(data.title)
                .font(.headline)
            
            // Pie chart (iOS 17+)
            Chart(data.dataPoints) { point in
                SectorMark(
                    angle: .value("Value", point.value),
                    innerRadius: .ratio(0.5)
                )
                .foregroundStyle(by: .value("Category", point.label))
            }
            .frame(height: 200)
        }
        .padding()
    }
}
