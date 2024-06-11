module Market = struct
  type stock = {
    name: string;
    mutable price: float;
    mu: float;  (* Expected return *)
    sigma: float  (* Volatility *)
  }

  (* Initial stocks with their respective mu and sigma values *)
  let stocks = [
    { name = "TSLA"; price = 100.0; mu = 0.2; sigma = 0.02 };
    { name = "AMZN"; price = 100.0; mu = 2.; sigma = 0.02 };
    { name = "AAPL"; price = 100.0; mu = 2.; sigma = 0.2 };
    { name = "GOOG"; price = 100.0; mu = 0.02; sigma = 0.2 }
  ]

  let tick delta_t =
    Printf.printf "Delta t = %.1f yr\n" delta_t

  let random_normal ~mu ~var =
    (* Use Box-Muller transform *)
    Random.self_init ();
    let u1 = Random.float 1.0 in
    let u2 = Random.float 1.0 in
    let z0 = sqrt (-2.0 *. log u1) *. cos (2.0 *. Float.pi *. u2) in
    let sigma = sqrt var in
    mu +. sigma *. z0

  let gmb_step (s: stock) (delta_t : float) =
    (* Update each stock's price using a Geometric Brownian Motion *)
    let drift = s.mu *. delta_t in
    let dW = random_normal ~mu:0. ~var:delta_t in
    let diffusion = s.sigma *. dW in
    s.price *. (drift +. diffusion)
  
  let update_prices delta_t =
    List.iter (fun s ->
      (* Choose the preferred update method here *)
      let dS = gmb_step s delta_t in
      s.price <- s.price +. dS
    ) stocks

  let get_price name =
    let stock = List.find (fun s -> s.name = name) stocks in
    stock.price

  let simulate n delta_t =
    for _ = 1 to n do
      tick delta_t;
      update_prices delta_t;
      List.iter (fun s -> Printf.printf "Stock: %s, Price: %.2f\n" s.name s.price) stocks;
      print_endline "-----"
    done
end

