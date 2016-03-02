# Linux Kernel Awareness QEMU-Test environment

The following steps assume that the reader is already experienced in cross compiling, and building kernels.
An ubuntu/debian build host is assumed.

## Prerequisites
You will need the following packages instaled on your system:
```
sudo apt-get update
sudo apt-get install -y build-essential git-core gcc-arm-linux-gnueabi qemu-system-arm
```

## Building
Clone this repository and type 'make' in the new folder. The scripts will clone the correct repositories, and build both binutils-gdb and the kernel configured for an ARM target.

```
git clone http://git.linaro.org/people/kieran.bingham/qemu-kernel.git
cd qemu-kernel
make
```
## Usage
Once the build process has completed, you will need to have two terminals open. I prefer to have these side-by-side for visibility

### Terminal 1: Running Kernel in QEmu
One terminal will be required to boot a kernel, and observe it's console output. These scripts disable graphics console capablity of qemu, simplifying the process to a text based view.
```
make qemu-run
```

### Terminal 2: Connecting to the QEmu kernel with GDB
In the other terminal, you will establish the connection to the running kernel:
```
make qemu-gdb
```

## Using LKD-C implementation
When you have a running kernel, and GDB session, you should find your self presented with a command prompt in gdb:
```
Remote debugging using localhost:32777
Enabling Linux Kernel Debugger 7.11-development build Mar  2 2016.
cpu_v7_do_idle () at /home/kbingham/qemu-kernel/sources/linux/arch/arm/mm/proc-v7.S:74
74              ret     lr
(gdb)
```

Initially, the Linux Kernel awareness is disabled, and can be introduced by executing the following command:
```
(gdb) set linux-awareness loaded
```

You should be presented with a list of new threads being added to the system:
```
[New [swapper/0]]
[New [kthreadd]]
[New [ksoftirqd/0]]
[New [kworker/0:0]]
...
```

At this point, you can inspect the thread list to see the new tasks integrated into the GDB thread list:
```
(gdb) info threads
  Id   Target Id         Frame 
* 1    [swapper/0] (TGID:0 <C0>) cpu_v7_do_idle () at linux/arch/arm/mm/proc-v7.S:74
  2    [swapper/1] (TGID:0 <C1>) cpu_v7_do_idle () at linux/arch/arm/mm/proc-v7.S:74
  3    [swapper/0] (TGID:1) context_switch (next=<optimized out>, prev=<optimized out>, rq=<optimized out>) at linux/kernel/sched/core.c:2706
  4    [kthreadd] (TGID:2) context_switch (next=<optimized out>, prev=<optimized out>, rq=<optimized out>) at linux/kernel/sched/core.c:2706
```

And you can select a thread, and backtrace it in the expected way:
```
(gdb) thread 47
[Switching to thread 47 ([kworker/1:1])]
#0  context_switch (next=<optimized out>, prev=<optimized out>, rq=<optimized out>)
    at /home/kbingham/qemu-kernel/sources/linux/kernel/sched/core.c:2706
2706            return finish_task_switch(prev);
(gdb) bt
#0  context_switch (next=<optimized out>, prev=<optimized out>, rq=<optimized out>) at linux/kernel/sched/core.c:2706
#1  __schedule (preempt=<optimized out>) at linux/kernel/sched/core.c:3180
#2  0xc09c7268 in schedule () at linux/kernel/sched/core.c:3209
#3  0xc025ef1c in worker_thread (__worker=0xee89a000) at linux/kernel/workqueue.c:2183
#4  0xc0263fe8 in kthread (_create=0xee83dac0) at linux/kernel/kthread.c:209
#5  0xc0210c38 in ret_from_fork () at linux/arch/arm/kernel/entry-common.S:118
Backtrace stopped: previous frame identical to this frame (corrupt stack?)
(gdb) 
```

