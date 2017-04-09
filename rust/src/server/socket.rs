use std::net::{SocketAddr, UdpSocket};
use std::io;
use std::time::Duration;

use net2;

pub trait SocketProvider<I> {
    fn bind(addr: &SocketAddr) -> Result<I, io::Error>;
    fn local_addr(&self) -> Result<SocketAddr, io::Error>;
    fn set_recv_timeout(&mut self, duration: Option<Duration>) -> Result<(), io::Error>;
    fn recv_from(&mut self, buf: &mut [u8]) -> Result<(usize, SocketAddr), io::Error>;
    fn send_to(&mut self, buf: &[u8], addr: &SocketAddr) -> Result<usize, io::Error>;
}

impl SocketProvider<UdpSocket> for UdpSocket {
    fn bind(addr: &SocketAddr) -> Result<UdpSocket, io::Error> {
        let socket = net2::UdpBuilder::new_v4()?.reuse_address(true)?.bind(addr)?;
        socket.set_nonblocking(true)?;

        Ok(socket)
    }

    fn local_addr(&self) -> Result<SocketAddr, io::Error> {
        UdpSocket::local_addr(self)
    }

    fn set_recv_timeout(&mut self, duration: Option<Duration>) -> Result<(), io::Error> {
        match duration {
            Some(duration) => {
                self.set_nonblocking(false)?;
                self.set_read_timeout(Some(duration))
            },
            None => {
                self.set_nonblocking(true)
            }
        }
    }

    fn recv_from(&mut self, buf: &mut [u8]) -> Result<(usize, SocketAddr), io::Error> {
        UdpSocket::recv_from(self, buf)
    }

    fn send_to(&mut self, buf: &[u8], addr: &SocketAddr) -> Result<usize, io::Error> {
        UdpSocket::send_to(self, buf, addr)
    }
}