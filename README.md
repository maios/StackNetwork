# StackNetwork

This is a brother of [Moya](https://github.com/Moya/Moya) with `URLSession` instead of using [Alamofire](https://github.com/Alamofire/Alamofire)

### Why?

- Because I wanted to learn more about [URLSession](https://developer.apple.com/documentation/foundation/urlsession) and this helped me bit by bit.
- Because I am fascinated by Moya about how declarative, testable, simple and easy-to-use it is.
- However, because Moya depends on Alamofire, which states that they do not support background transfer [here](https://github.com/Alamofire/Alamofire/issues/1052#issuecomment-180844423), this frustrated me when working in previous projects that used Alamofire, so I thought why not make a Moya duplicate using `URLSession` so I will have more control in that sense.
- With Moya, you can have as many plugins as you want to modify a request before it is sent, I do not want this behavior, I want to have one and only one request adapter like Alamofire does, and plugins should only be observing when request is sent/completed. This is just my opinion, so don't judge me on this, I just wanted to create something that fits my purposes.

### Usage

Pretty much the same to Moya :-p
