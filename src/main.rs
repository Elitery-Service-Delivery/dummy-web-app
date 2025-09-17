use hyper::service::{make_service_fn, service_fn};
use hyper::{Body, Method, Request, Response, Server, StatusCode};
use ip_fetcher::{IpInfo, CachedResponse, CACHE_DURATION};
use once_cell::sync::Lazy;
use std::convert::Infallible;
use std::sync::{Arc, Mutex};
use std::time::Instant;

static CACHE: Lazy<Arc<Mutex<Option<CachedResponse>>>> = Lazy::new(|| Arc::new(Mutex::new(None)));

async fn fetch_ip_info() -> Result<IpInfo, Box<dyn std::error::Error + Send + Sync>> {
    let client = reqwest::Client::new();
    let response = client
        .get("https://ifconfig.co/json")
        .header("User-Agent", "rust-ip-fetcher/1.0")
        .send()
        .await?;

    let ip_info: IpInfo = response.json().await?;
    Ok(ip_info)
}

async fn get_cached_or_fetch() -> Result<IpInfo, Box<dyn std::error::Error + Send + Sync>> {
    // Check if we have valid cached data
    let cached_data = {
        let cache = CACHE.lock().unwrap();
        if let Some(cached) = cache.as_ref() {
            if cached.timestamp.elapsed() < CACHE_DURATION {
                println!("Returning cached data (age: {:?})", cached.timestamp.elapsed());
                Some(cached.data.clone())
            } else {
                None
            }
        } else {
            None
        }
    };
    
    if let Some(data) = cached_data {
        return Ok(data);
    }
    
    println!("Cache miss or expired, fetching fresh data...");
    let fresh_data = fetch_ip_info().await?;
    
    // Update cache
    {
        let mut cache = CACHE.lock().unwrap();
        *cache = Some(CachedResponse {
            data: fresh_data.clone(),
            timestamp: Instant::now(),
        });
    }
    
    Ok(fresh_data)
}

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    match (req.method(), req.uri().path()) {
        (&Method::GET, "/") => {
            match get_cached_or_fetch().await {
                Ok(ip_info) => {
                    println!("Successfully returned IP info: {}", ip_info.ip);
                    let json = serde_json::to_string(&ip_info).unwrap_or_else(|_| "{}".to_string());
                    Ok(Response::builder()
                        .status(StatusCode::OK)
                        .header("content-type", "application/json")
                        .header("access-control-allow-origin", "*")
                        .body(Body::from(json))
                        .unwrap())
                }
                Err(e) => {
                    eprintln!("Error fetching IP info: {}", e);
                    Ok(Response::builder()
                        .status(StatusCode::INTERNAL_SERVER_ERROR)
                        .header("content-type", "application/json")
                        .header("access-control-allow-origin", "*")
                        .body(Body::from(r#"{"error": "Failed to fetch IP information"}"#))
                        .unwrap())
                }
            }
        }
        (&Method::GET, "/health") => {
            Ok(Response::builder()
                .status(StatusCode::OK)
                .header("content-type", "text/plain")
                .body(Body::from("OK"))
                .unwrap())
        }
        _ => {
            Ok(Response::builder()
                .status(StatusCode::NOT_FOUND)
                .header("content-type", "application/json")
                .body(Body::from(r#"{"error": "Not found"}"#))
                .unwrap())
        }
    }
}

#[tokio::main]
async fn main() {
    println!("Starting IP Fetcher service...");

    let make_svc = make_service_fn(|_conn| async {
        Ok::<_, Infallible>(service_fn(handle_request))
    });

    let addr = ([0, 0, 0, 0], 3000).into();
    let server = Server::bind(&addr).serve(make_svc);

    println!("Server listening on port 3000");
    println!("Visit http://localhost:3000/ to get your IP information");

    if let Err(e) = server.await {
        eprintln!("Server error: {}", e);
    }
}