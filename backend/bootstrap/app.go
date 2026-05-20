package bootstrap

// Application은 앱 수명주기 동안 공유되는 인프라 의존성을 보관한다.
type Application struct {
	Env *Env
}

func App() Application {
	env, err := NewEnv()
	if err != nil {
		panic(err)
	}
	return Application{Env: env}
}
