#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
//#define DEBUG_LOG(msg,...)
#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

  // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
  // hint: use a cast like the one below to obtain thread arguments from your parameter
  //struct thread_data* thread_func_args = (struct thread_data *) thread_param;

  struct thread_data *td = (struct thread_data*) thread_param;

  int rc1, rc2;
  
  usleep(1000 * td->wait_to_obtain_ms);
  rc1 = pthread_mutex_lock(td->mutex);

  if (rc1) {
    td->thread_complete_success = false;
    ERROR_LOG("Error locking mutex");
    return td;
  }
  
  usleep(1000 * td->wait_to_release_ms);  
  rc2 = pthread_mutex_unlock(td->mutex);

  if (rc2) {
    td->thread_complete_success = false;
    ERROR_LOG("Error unlocking mutex");
    return td;
  }
  
  td->thread_complete_success = true;
  return td;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
  /**
   * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
   * using threadfunc() as entry point.
   *
   * return true if successful.
   *
   * See implementation details in threading.h file comment block
   */

  struct thread_data *td = malloc(sizeof(struct thread_data));
  td->mutex = mutex;
  td->wait_to_obtain_ms = wait_to_obtain_ms;
  td->wait_to_release_ms = wait_to_release_ms;

  int rc;
  rc = pthread_create(thread, NULL, &threadfunc, td);  

  if (rc) {
    ERROR_LOG("Error creating thread");
  }
  
  return rc == 0;
}

