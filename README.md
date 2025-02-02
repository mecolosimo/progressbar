# progressbar
Progressbar in V based on [progressbar](https://github.com/doches/progressbar) by Trevor Fountain and Johannes Buchner.

## What is this thing?

progressbar is for displaying attractive progress bars on the command line. It's heavily influenced by the ruby ProgressBar
gem, whose api and behaviour it imitates. Really want something like [tqdm](https://github.com/tqdm/tqdm). But this was simpler. 

Example usage:

```v
import time
import progressbar as prog

fn main() {
	mut p := prog.progressbar_new("Testing", 100) or { panic('Something went wrong with progressbar_new')}
	for i := 0; i < 100; i++ {
		// Simulating doing some stuff
		time.sleep(1 * time.second)
		p.progressbar_inc()
	}
	p.progressbar_finish()
}
```

# installing

Eventually, I will put this in [vpm](https://vpm.vlang.io/) but for now:

```bash
v install https://github.com/mecolosimo/progressbar
```