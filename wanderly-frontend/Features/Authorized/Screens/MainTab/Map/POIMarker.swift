struct POIMarker: Identifiable {
    enum POIType {
        case greenZone
        case cafe
    }

    let id: UUID
    let type: POIType
    let name: String
    let coordinate: CLLocationCoordinate2D
}