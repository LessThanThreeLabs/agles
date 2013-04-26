import eventlet

from nose.tools import *

from util.test import BaseIntegrationTest, Timeout
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from verification.verifier_pool import VerifierPool


class SimpleVerifierPool(VerifierPool):
	def spawn_verifier(self, verifier_number):
		eventlet.sleep()
		return verifier_number

	def remove_verifier(self, verifier_number):
		del self.verifiers[verifier_number]


class VerifierPoolTest(BaseIntegrationTest, ModelServerTestMixin, RabbitMixin):
	@classmethod
	def setup_class(cls):
		super(VerifierPoolTest, cls).setup_class()
		cls._purge_queues()

	def setUp(self):
		self._start_model_server()

	def tearDown(self):
		super(VerifierPoolTest, self).tearDown()
		self._stop_model_server()
		self._purge_queues()

	@Timeout(time=2)
	def test_verifier_pool_cap(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=5)
		self._assert_pool_size(verifier_pool, 0, 5, 0)

		results_queue = eventlet.queue.Queue()

		def get():
			results_queue.put(verifier_pool.get())

		greenlets = [eventlet.spawn(get) for i in range(10)]
		results = sorted([results_queue.get() for i in range(5)])
		assert_equal(range(5), results)
		self._assert_pool_size(verifier_pool, 0, 0, 5)

		for greenlet in greenlets:
			greenlet.kill()

	@Timeout(time=2)
	def test_resource_freeing(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=0)
		self._assert_pool_size(verifier_pool, 5, 0, 0)

		results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue, keep_result=True) for i in range(5)]
		results = sorted([results_queue.get() for i in range(5)])
		assert_equal(range(5), results)
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		[verifier_pool.remove(i) for i in range(5)]
		self._assert_pool_size(verifier_pool, 5, 0, 0)

	@Timeout(time=2)
	def test_resource_freeing_and_allocation(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=3)
		self._assert_pool_size(verifier_pool, 2, 3, 0)

		results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue, keep_result=True) for i in range(5)]
		results = sorted([results_queue.get() for i in range(5)])
		assert_equal(range(5), results)
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		[verifier_pool.remove(i) for i in range(5)]
		self._assert_pool_size(verifier_pool, 2, 3, 0)

	@Timeout(time=20)
	def test_semirandom_stability(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=20, min_unallocated=4)
		self._assert_pool_size(verifier_pool, 16, 4, 0)

		results_queue = eventlet.queue.Queue()
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 1000, results_queue, keep_result=True) for i in range(13)]
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 1000, empty_results_queue) for i in range(25)]

		for i in range(25):
			assert_is_none(empty_results_queue.get())
		results = sorted([results_queue.get() for i in range(13)])
		assert_equal(13, len(set(results)))

		self._assert_pool_size(verifier_pool, 3, 4, 13)

	@Timeout(time=2)
	def test_increase_max_size(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=3, min_unallocated=1)
		self._assert_pool_size(verifier_pool, 2, 1, 0)

		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=1)
		verifier_pool._fill_to_min_unallocated()
		self._assert_pool_size(verifier_pool, 4, 1, 0)

		verifier_pool.reinitialize(max_verifiers=10, min_unallocated=1)
		results = sorted([verifier_pool.get() for i in range(10)])
		assert_equal(range(10), results)

	@Timeout(time=2)
	def test_decrease_max_size(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=10, min_unallocated=2)
		self._assert_pool_size(verifier_pool, 8, 2, 0)

		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=2)
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 3, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(5)])
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		assert_equal(range(5), remaining)

	@Timeout(time=5)
	def test_scale_max_down_up(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=10, min_unallocated=2)
		self._assert_pool_size(verifier_pool, 8, 2, 0)

		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=2)
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 3, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(5)])
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		assert_equal(range(5), remaining)

		verifier_pool.reinitialize(max_verifiers=10, min_unallocated=2)
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 10, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 3, 2, 5)

		[verifier_pool.remove(i) for i in list(verifier_pool.allocated_slots)]

		self._assert_pool_size(verifier_pool, 8, 2, 0)

		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 10, empty_results_queue) for i in range(3)]

		self._assert_pool_size(verifier_pool, 8, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(10)])
		self._assert_pool_size(verifier_pool, 0, 0, 10)
		assert_equal(range(10), remaining)

	@Timeout(time=5)
	def test_scale_max_up_down(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=2)
		self._assert_pool_size(verifier_pool, 3, 2, 0)

		verifier_pool.reinitialize(max_verifiers=10, min_unallocated=2)
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 10, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 8, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(10)])
		self._assert_pool_size(verifier_pool, 0, 0, 10)
		assert_equal(range(10), remaining)

		[verifier_pool.remove(i) for i in list(verifier_pool.allocated_slots)]

		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=2)
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 10, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 3, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(5)])
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		assert_equal(range(5), remaining)

	@Timeout(time=2)
	def test_increase_min_unallocated(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=1)
		self._assert_pool_size(verifier_pool, 4, 1, 0)

		verifier_pool.min_unallocated = 3
		verifier_pool._fill_to_min_unallocated()
		self._assert_pool_size(verifier_pool, 2, 3, 0)

		verifier_pool.min_unallocated = 5
		results = sorted([verifier_pool.get() for i in range(5)])
		assert_equal(range(5), results)

	@Timeout(time=2)
	def test_decrease_min_unallocated(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=5, min_unallocated=5)
		self._assert_pool_size(verifier_pool, 0, 5, 0)

		verifier_pool.min_unallocated = 3
		empty_results_queue = eventlet.queue.Queue()
		self._recycle_multiple_times(verifier_pool, 5, empty_results_queue)
		self._assert_pool_size(verifier_pool, 2, 3, 0)

		verifier_pool.min_unallocated = 1
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, empty_results_queue) for i in range(3)]

		for i in xrange(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 4, 1, 0)

		verifier_pool.min_unallocated = 5
		results = sorted([verifier_pool.get() for i in range(5)])
		assert_equal(range(5), results)

	@Timeout(time=2)
	def test_queuing_reinitialize_up_down(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=8, min_unallocated=5)
		results_queue = eventlet.queue.Queue()
		self._assert_pool_size(verifier_pool, 3, 5, 0)

		# verifier_pool._initializing acts as a lock
		verifier_pool._initializing = True
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=10, min_unallocated=4)
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=3, min_unallocated=1)  # This should be the last to run
		verifier_pool._initializing = False
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=2)

		for i in xrange(15):
			assert_is_none(results_queue.get())

		self._assert_pool_size(verifier_pool, 2, 1, 0)

	@Timeout(time=2)
	def test_queuing_reinitialize_down_up(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=8, min_unallocated=5)
		results_queue = eventlet.queue.Queue()
		self._assert_pool_size(verifier_pool, 3, 5, 0)

		# verifier_pool._initializing acts as a lock
		verifier_pool._initializing = True
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=3, min_unallocated=1)
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=10, min_unallocated=4)  # This should be the last to run
		verifier_pool._initializing = False
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, results_queue) for i in range(5)]
		verifier_pool.reinitialize(max_verifiers=5, min_unallocated=2)

		for i in xrange(15):
			assert_is_none(results_queue.get())

		self._assert_pool_size(verifier_pool, 6, 4, 0)

	def _recycle_multiple_times(self, verifier_pool, recycle_count, results_queue, keep_result=False):
		for i in range(recycle_count - 1):
			verifier = verifier_pool.get()
			eventlet.sleep()
			verifier_pool.remove(verifier)
		if keep_result:
			results_queue.put(verifier_pool.get())
		else:
			results_queue.put(None)

	def _assert_pool_size(self, pool, free_size, unallocated_size, allocated_size):
		eventlet.sleep(0.1)

		assert_equal(free_size, pool.free_slots.qsize() - len(pool.to_remove_free))
		assert_equal(unallocated_size, len(pool.unallocated_slots))
		assert_equal(allocated_size, len(pool.allocated_slots))
