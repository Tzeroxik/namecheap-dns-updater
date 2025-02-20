use std::env::args;
use std::fmt::{Debug, Display, Formatter};
use std::time::Duration;

use reqwest::Client;

static SLEEP_TIME: Duration = Duration::from_secs(5 * 60);
static GET_IP_ENDPOINTS: [&str; 4] = [
    "",
    "",
    "",
    ""
];

#[derive(Debug)]
struct Profile {
    host: String,
    domain: String,
    api_key: String,
}

#[derive(Debug)]
enum UpdateError {
    MissingArg(&'static str),
    FailedToGetPublicIp(Vec<reqwest::Error>),
}

impl Display for UpdateError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        
        let msg = match self {
            UpdateError::MissingArg(name) => 
                format!("Missing required argument: {}" , name),
            UpdateError::FailedToGetPublicIp(errors) => 
                format!("Failed to get public IP: {errors:?}"),
        };
        
        write!(f, "{msg}")
    }
}



#[tokio::main]
async fn main() {

    let http_client = Client::new();
    
    let profiles = 
        args()
            .skip(1)
            .map(try_parse_profile)
            .collect::<Result<Vec<Profile>, UpdateError>>()
            .unwrap_or_else(|error| panic!("{error}"));

    loop {
        let public_ip =
            get_public_ip(&http_client, &GET_IP_ENDPOINTS)
                .await
                .unwrap_or_else(|error| panic!("{error}"));

        for profile in &profiles {
            println!("public IP = {public_ip}");
        }
        tokio::time::sleep(SLEEP_TIME).await;
    }
    
}


async fn get_public_ip_from_endpoint(endpoint: &str, client: &Client) -> Result<String, reqwest::Error> {
    client.get(endpoint).send().await?.text().await
}

async fn get_public_ip(client: &Client, endpoints: &[&str]) -> Result<String, UpdateError> {
    let mut errors: Vec<reqwest::Error> = Vec::new();
    for &endpoint in endpoints {
        match get_public_ip_from_endpoint(endpoint, client).await { 
            Ok(public_ip) => return Ok(public_ip),
            Err(error) => errors.push(error),
        }
    }
    Err(UpdateError::FailedToGetPublicIp(errors))
}

fn try_parse_profile(profile: String) -> Result<Profile, UpdateError> {
    let mut fields_iter=
        profile.split(":")
            .skip(1)
            .map(|s| s.to_owned());
    
    let profile = Profile {
        host: try_next(&mut fields_iter, "host")?,
        domain: try_next(&mut fields_iter, "domain")?,
        api_key: try_next(&mut fields_iter, "api_key")?,
    };
    
    Ok(profile)
}


#[inline]
fn try_next(fields: &mut impl Iterator<Item=String>, field: &'static str) -> Result<String, UpdateError> {
    fields.next().ok_or(UpdateError::MissingArg(field))
}