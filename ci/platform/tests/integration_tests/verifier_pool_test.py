import eventlet

from nose.tools import *

from util.test import BaseIntegrationTest, Timeout
from util.test.mixins import ModelServerTestMixin, RabbitMixin
from verification.verifier_pool import VerifierPool


class SimpleVerifierPool(VerifierPool):
	def spawn_verifier(self, verifier_number):
		return verifier_number


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

	@Timeout(time=10)
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

		verifier_pool.max_verifiers = 5
		verifier_pool._fill_to_min_unallocated()
		self._assert_pool_size(verifier_pool, 4, 1, 0)

		verifier_pool.max_verifiers = 10
		results = sorted([verifier_pool.get() for i in range(10)])
		assert_equal(range(10), results)

	@Timeout(time=2)
	def test_decrease_max_size(self):
		verifier_pool = SimpleVerifierPool(max_verifiers=10, min_unallocated=2)
		self._assert_pool_size(verifier_pool, 8, 2, 0)

		verifier_pool.max_verifiers = 5
		empty_results_queue = eventlet.queue.Queue()
		[eventlet.spawn(self._recycle_multiple_times, verifier_pool, 5, empty_results_queue) for i in range(3)]

		for i in range(3):
			assert_is_none(empty_results_queue.get())

		self._assert_pool_size(verifier_pool, 3, 2, 0)

		remaining = sorted([verifier_pool.get() for i in range(5)])
		self._assert_pool_size(verifier_pool, 0, 0, 5)
		assert_equal(range(5), remaining)

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
		assert_equal(free_size, pool.free_slots.qsize())
		assert_equal(unallocated_size, len(pool.unallocated_slots))
		assert_equal(allocated_size, len(pool.allocated_slots))
