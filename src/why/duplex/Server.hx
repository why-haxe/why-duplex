package why.duplex;

interface Server {
	final connected:Signal<Client>;
	final errors:Signal<Error>;
}