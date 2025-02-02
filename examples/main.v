// Copyright (c) 2025 Marc E. Colosimo. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module main

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