// Copyright (c) 2025 Marc E. Colosimo. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module progressbar

import term
import time
import strconv

// How wide we assume the screen is if termcap fails.
const default_screen_width = 80

// The smallest that the bar can ever be (not including borders)
const minimum_bar_width = 10

// The format in which the estimated remaining time will be reported
const eta_format = "ETA:%2dh%02dm%02ds"

// The maximum number of characters that the ETA_FORMAT can ever yield
const eta_format_length = 13

// The amount of width taken up by the border of the bar component.
const whitespace_length = 2

// The amount of width taken up by the border of the bar component.
const bar_border_width = 2

struct Format {
	begin 	string
	end		string
	fill	string
}

struct Progessbar {

	max 	u64  		@[xdoc: 'Maximum value']

	start	time.Time	@[xdoc: 'Time progressbar was started']

mut:
	value	u64			@[xdoc: 'Current value']

	label	string		@[xdoc: 'Label']

	format 	Format		@[xdoc: 'Characters for the beginning, filling and end of the progressbar. E.g. |###    | has |#|']
}

struct Progressbar_time_components {
mut:
	hours 	u64
	minutes	u64
	seconds u64
}

// difftime Returns diffence in time
@[inline]
fn difftime(a time.Time, b time.Time) f64 {
	return (a - b).seconds()
}

@[inline]
fn (bar &Progessbar) progressbar_remaining_seconds() u64 {
  offset := difftime(time.now(), bar.start)
  if bar.value > 0 && offset > 0 {
    return u64((offset / f64(bar.value)) * (bar.max - bar.value))
  } else {
    return 0
  }
}

@[inline]
fn progressbar_calc_time_components(seconds u64) Progressbar_time_components {
	hours 		:= seconds / 3600
  	mut secs	:= seconds - hours * 3600
  	minutes 	:= secs / 60
 	secs 		-= minutes * 60

	return Progressbar_time_components {
		hours: 		hours
		minutes:	minutes		
		seconds:	seconds
	}
}

@[inline]
fn progressbar_max(x int, y int) int {
  return if x > y { x } else { y }
}

@[inline]
fn progressbar_bar_width(screen_width int, label_length int) int {

	return progressbar_max(minimum_bar_width, screen_width - label_length - eta_format_length - whitespace_length)
}

@[inline]
fn get_screen_width() int {
	columns, _ := term.get_terminal_size()
	return columns
}

@[inline]
fn (bar &Progessbar) progressbar_draw() {
	screen_width 	:= get_screen_width()
	label_length 	:= bar.label.len
	mut bar_width	:= progressbar_bar_width(screen_width, label_length)
	label_width		:= progressbar_label_width(screen_width, label_length, bar_width)

	progressbar_completed	:= bar.value >= bar.max
	bar_piece_count			:= bar_width - bar_border_width
	bar_piece_current		:= if progressbar_completed {
									f64(bar_piece_count)
								} else {
									bar_piece_count * ( bar.value / f64(bar.max))
								}

	eta := 	if progressbar_completed {
				progressbar_calc_time_components(u64(difftime(time.now(), bar.start)))
			} else {
				progressbar_calc_time_components(bar.progressbar_remaining_seconds())
			}
	
	if label_width == 0 {
		// The label would usually have a trailing space, but in the case that we don't print
    	// a label, the bar can use that space instead.
    	bar_width += 1
	} else {
		 // Draw the label
   		eprint(bar.label);
   		eprint(' ');
	}

	// Draw the progressbar
	eprint(bar.format.begin)
	progressbar_write_char(bar.format.fill, bar_piece_current)
	progressbar_write_char(' ', bar_piece_count - bar_piece_current - 1)
	eprint(bar.format.end,)

	// Draw the ETA
	eprint(' ')
	eprint( unsafe { strconv.v_sprintf(eta_format, eta.hours, eta.minutes, eta.seconds) } )
	eprint('\r')	

	flush_stderr()
}

@[inline]
fn progressbar_label_width(screen_width int, label_length int, bar_width int) int {
	eta_width := eta_format_length

	// If the progressbar is too wide to fit on the screen, we must sacrifice the label.
	if label_length + bar_width + eta_width + 2 > screen_width {
		return progressbar_max(0, screen_width - bar_width - eta_width - whitespace_length)
	} else {
		return label_length
	}
}

@[inline]
fn progressbar_write_char(ch string, times f64) {
	mut i := 0
	for {
		eprint(ch)
		i++
		if i >= times {
			break
		}
	}
}

// progessbar_update Increment an existing progressbar by `value` steps.
fn (mut bar Progessbar) progessbar_update(value u64) {
	bar.value = value
	bar.progressbar_draw()
}

// progressbar_new_with_format Create a new progress bar with the specified label, max number of steps, and format string.
// Note that `format` must be exactly three characters long, e.g. "<->" to render a progress
// bar like "<---------->". Returns NULL if there isn't enough memory to allocate a progressbar
fn progressbar_new_with_format(label string, max u64, format string) &Progessbar {
	assert 3 == format.len, "format must be 3 characters in length"
	
	f := Format {
		begin:	format[0].ascii_str()
		fill:	format[1].ascii_str()
		end:	format[2].ascii_str()
	}

	mut new := &Progessbar {
		max:	max
		value:	0
		start:	time.now()
		format: f
	}

	new.progressbar_update_label(label)
	new.progressbar_draw()

	return new
}

// progressbar_new Configures a progressbar with the provided arguments. Note that the user is responsible for disposing
//		      of the progressbar via progressbar_finish when finished with the object.
pub fn progressbar_new(label string, max u64) &Progessbar {
	return progressbar_new_with_format(label, max, "|=|")
}

// progressbar_update Set the current status on the given progressbar.
pub fn (mut bar Progessbar) progressbar_update(value u64) {
	bar.value++
	bar.progressbar_draw()
}

// progressbar_inc Increment the given progressbar. Don't increment past the initialized # of steps, though.
pub fn (mut bar Progessbar) progressbar_inc() {
	bar.progressbar_update(bar.value + 1)
}

// progressbar_update_label Set the label of the progressbar. Note that no rendering is done. The label is simply set so that the next
// rendering will use the new label. To immediately see the new label, call progressbar_draw.
// Does not update display or copy the label
pub fn (mut bar Progessbar) progressbar_update_label(label string) {
	bar.label = label
}

// progressbar_finish Call this when you're done, or if you break out
// partway through.
pub fn (mut bar Progessbar) progressbar_finish() {
	// Make sure we fill the progressbar so things look complete.
	bar.progressbar_draw()

	// Print a newline, so that future outputs to stderr look prettier
	eprint("\n")
}
