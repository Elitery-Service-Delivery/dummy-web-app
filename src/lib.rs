use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct IpInfo {
    pub ip: String,
    pub country: Option<String>,
    pub country_code: Option<String>,
    pub city: Option<String>,
    pub region: Option<String>,
    pub region_code: Option<String>,
    pub zip: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub timezone: Option<String>,
    pub asn: Option<String>,
    pub org: Option<String>,
}

#[derive(Debug, Clone)]
pub struct CachedResponse {
    pub data: IpInfo,
    pub timestamp: Instant,
}

pub const CACHE_DURATION: Duration = Duration::from_secs(60); // 1 minute

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ip_info_structure() {
        let ip_info = IpInfo {
            ip: "192.168.1.1".to_string(),
            country: Some("Test Country".to_string()),
            country_code: Some("TC".to_string()),
            city: Some("Test City".to_string()),
            region: Some("Test Region".to_string()),
            region_code: Some("TR".to_string()),
            zip: Some("12345".to_string()),
            latitude: Some(40.7128),
            longitude: Some(-74.0060),
            timezone: Some("UTC".to_string()),
            asn: Some("AS12345".to_string()),
            org: Some("Test Org".to_string()),
        };

        assert_eq!(ip_info.ip, "192.168.1.1");
        assert_eq!(ip_info.country.unwrap(), "Test Country");
    }

    #[test]
    fn test_cache_duration() {
        assert_eq!(CACHE_DURATION.as_secs(), 60);
    }
}