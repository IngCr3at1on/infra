package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

var (
	cpuTempPrefix string
	threshold     int
	controlled    bool
	enableTicker  bool
	host          string
	user          string
	pass          string
)

func init() {
	flag.StringVar(&cpuTempPrefix, `match-prefix`, `Temp`, `Set the CPU temperature match prefix`)
	flag.IntVar(&threshold, `threshold`, 60, `Set the max average CPU temperature threshold`)
	flag.BoolVar(&enableTicker, `watch`, false, `Run the functionality inside a 3 minute ticker to watch the temperature`)
	flag.StringVar(&host, `host`, ``, `the remote host to call with ipmi (if any)`)
	flag.StringVar(&user, `user`, ``, `the remote user to use with ipmi (if any)`)
	flag.StringVar(&pass, `pass`, ``, `the remote pass to use with ipmi (if any)`)
	flag.Parse()
}

func _main() error {
	avg, err := getCPUTemp()
	if err != nil {
		return err
	}

	if avg > threshold {
		controlled = false
		fmt.Printf("\033[33mEnabling Automatic Fan Control\033[33m")
		var args []string
		if host != `` {
			args = append(args, `-I`, `lanplus`, `-H`, host, `-U`, user, `-P`, pass)
		}
		args = append(args, `raw`, `0x30`, `0x30`, `0x01`, `0x01`)

		err = _exec(nil, `ipmitool`, args...)
		if err != nil {
			return err
		}

		return nil
	}

	if !controlled {
		fmt.Printf("\033[32mDisabling Automatic Fan Control\033[32m")
		var args []string
		if host != `` {
			args = append(args, `-I`, `lanplus`, `-H`, host, `-U`, user, `-P`, pass)
		}
		args = append(args, `raw`, `0x30`, `0x30`, `0x01`, `0x00`)

		err = _exec(nil, `ipmitool`, args...)
		if err != nil {
			return err
		}

		fmt.Printf("\033[32mSetting Fan Speed\033[32m")
		args = make([]string, 0, 0)
		if host != `` {
			args = append(args, `-I`, `lanplus`, `-H`, host, `-U`, user, `-P`, pass)
		}
		args = append(args, `raw`, `0x30`, `0x30`, `0x02`, `0xff`, `0x0a`)

		err = _exec(nil, `ipmitool`, args...)
		if err != nil {
			return err
		}

		controlled = true
	}

	return nil
}

func main() {
	if err := _main(); err != nil {
		fmt.Printf("\033[31m%s\033[31m\n", err.Error())
		os.Exit(1)
	}

	if enableTicker {
		ticker := time.NewTicker(3 * time.Minute)
		for {
			select {
			case <-ticker.C:
				if err := _main(); err != nil {
					fmt.Printf("\033[31m%s\033[31m\n", err.Error())
					os.Exit(1)
				}
			}
		}
	}

	fmt.Printf("\033[34mApparently BumbaCLot is handsome?\033[34m\n")
}

// getCPUTemp returns the average CPU temperature.
func getCPUTemp() (int, error) {
	var ret bytes.Buffer
	err := _exec(&ret, `ipmitool`, `sdr`, `type`, `temperature`)
	if err != nil {
		return 0, err
	}

	// TODO: clean this up, this can be done in a single more clean loop.
	var cpuTempStrs []string
	for _, str := range strings.Split(strings.TrimSuffix(ret.String(), "\n"), "\n") {
		if strings.HasPrefix(str, cpuTempPrefix) {
			cpuTempStrs = append(
				cpuTempStrs,
				strings.TrimSpace(strings.TrimSuffix(str, `degrees C`)),
			)
		}
	}

	var (
		total   int
		divisor int
	)
	for _, str := range cpuTempStrs {
		fields := strings.Fields(str)
		t, err := strconv.Atoi(fields[len(fields)-1])
		if err != nil {
			return 0, err
		}

		total += t
		divisor++
	}

	return total / divisor, nil
}

func _exec(out *bytes.Buffer, command string, params ...string) error {
	cmd := exec.Command(command, params...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	var errb bytes.Buffer
	if out != nil {
		cmd.Stdout = out
		cmd.Stderr = &errb
	}

	if err := cmd.Run(); err != nil {
		if out != nil {
			return fmt.Errorf("error (%s) executing command: %s, %v : %s", errb.String(), command, cmd.Args, err.Error())
		}

		return fmt.Errorf("error executing command: %s, %v : %s", command, cmd.Args, err.Error())
	}

	return nil
}
