
class Singleton
{
public:
	static Singleton& get();
	~Singleton();

private:
	Singleton();
};

Singleton& Singleton::get()
{
	static Singleton s_instance;
	return s_instance;
}

