package main

import (
	"os/exec"
	"fmt"
	"time"
	"os"
	"bufio"
	"strings"
	"strconv"
)

func main() {
	argCount := len(os.Args)

	if argCount > 2 {
		appName := os.Args[0]
		fmt.Printf("usage: %s [filename]\n", appName)
		return
	}

	if argCount == 1 {
		playFile(os.Stdin)
	} else {
		f, err := os.Open(os.Args[1])
		
		if err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)
		}
		defer f.Close()
		playFile(f)
	}
}

func playFile(file *os.File) {
	input := bufio.NewScanner(file)
	lastStep := 0
	
	for input.Scan() {
		line := input.Text()
		info := strings.Split(line, ":")

		if len(info) != 2 {
			fmt.Errorf("Invalid input: %s", line)
			return
		}
		notes := strings.Split(info[1], ",")

		if len(notes) == 0 {
			fmt.Errorf("Invalid input: %s", line)
			return
		}
		s := strings.Trim(info[0], " ")
		step := lastStep

		if len(s) > 0 {
			var err error = nil
			step, err = strconv.Atoi(s)

			if err != nil {
				fmt.Errorf("Invalid input: %s", line)
				return
			}
		}
		delay := step * 10
		time.Sleep(time.Duration(delay) * time.Millisecond)
		lastStep = step

		for i, v := range notes {
			v = strings.Trim(v, " ")
			p, err := strconv.Atoi(v)

			if err != nil {
				fmt.Errorf("Invalid input: %s", line)
				return
			}

			if i == 0 {
				fmt.Printf("%d", p)
			} else {
				fmt.Printf(" %d", p)
			}
			go play(p)
		}
		fmt.Println()
	}
	// TODO (lgmenchaca): detect when all goroutines are done
	time.Sleep(time.Duration(100) * time.Millisecond)
}

func play(pin int) {
	// TODO (lgmenchaca): embed resources in the final executable
	file := fmt.Sprintf("./resources/pin_%d.mp3", pin + 1)

	// TODO (lgmenchaca): use an audio library instead of relying on the OS
	_, err := exec.Command("afplay", file).Output()

	if err != nil {
		fmt.Errorf("Error playing %s\n", file)
	}
}