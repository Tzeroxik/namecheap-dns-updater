use std::error::Error;
use std::fmt::{Debug, Display, Formatter};

#[derive(Debug)]
pub enum Param {
    Host { 
        host: String,
        domain: String,
    },
    ApiKey {
        key: String,
        domain: String,
    },
    Url(String),
}

impl Param {
    pub fn try_parse(s: &str) -> Result<Param, ParamError> {
        
        if let Some((p_type, p_value)) = s.split_once("=") {
            match p_type { 
                "host" => Param::parse_host(p_value),
                "key" => Param::parse_key(p_value),
                "url" => Ok(Param::Url(p_value.to_string())),
                p => Err(ParamError::UnknownParam(p.to_string())),
            }
        } else {
            Err(ParamError::InvalidParamFormat(s.to_string())) 
        }
    }
    fn parse_host(value: &str) -> Result<Param, ParamError> {
        todo!()
    }
    fn parse_key(p0: &str) -> Result<Param, ParamError> {
        todo!()
    }
}

impl Display for Param {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

#[derive(Debug)]
pub enum ParamError {
    InvalidParamFormat(String),
    UnknownParam(String),
}

impl Display for ParamError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl Error for ParamError {}