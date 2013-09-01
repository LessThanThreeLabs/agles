from nose.tools import *
from util.test import BaseUnitTest
from virtual_machine.virtual_machine import VirtualMachine

ImageVersion = VirtualMachine.ImageVersion


class VirtualMachineUtilTest(BaseUnitTest):
	def setUp(self):
		pass

	def tearDown(self):
		pass

	def test_image_version_equality(self):
		assert_equal(ImageVersion('42'), ImageVersion('42'))
		assert_equal(ImageVersion('42'), ImageVersion(42))
		assert_equal(ImageVersion('42'), 42)
		assert_equal(ImageVersion('1.2.3.4.5'), ImageVersion('1.2.3.4.5'))
		assert_equal(8.1, ImageVersion('8.1'))

		assert_not_equal(8, ImageVersion('8.1'))
		assert_not_equal(4.2, ImageVersion('4'))
		assert_not_equal(ImageVersion('42.0.1'), ImageVersion('42.0.2'))

	def test_image_version_comparison(self):
		assert_less(ImageVersion(42), ImageVersion(43))
		assert_less(ImageVersion(42), ImageVersion(42.1))
		assert_less(ImageVersion(41.5), 41.6)

		assert_greater(ImageVersion('1.0.1'), ImageVersion('1.0'))
		assert_greater(ImageVersion('1.0.1'), 1.0)
		assert_greater(ImageVersion('1.0.1'), '1.0')
		assert_greater(ImageVersion('3'), 2.1)
		assert_greater(ImageVersion('4.0.0.0.0.0.0.1'), 4)
		assert_greater(ImageVersion('4.0.0.0.0.0.0.1'), '4.0.0.0.0.0.0.0.1')

	def test_to_string(self):
		assert_equal('42', str(ImageVersion(42)))
		assert_equal('1.0', str(ImageVersion('1.0')))
		assert_equal('1.0', str(ImageVersion(1.0)))
		assert_equal('1.2.3.4.5', str(ImageVersion('1.2.3.4.5')))

	def test_add(self):
		assert_equal('5', ImageVersion(2) + ImageVersion(3))
		assert_equal(ImageVersion(5), ImageVersion(3) + 2)

		assert_equal('1.2', ImageVersion(1.1) + ImageVersion('0.1'))
		assert_equal('1.2', ImageVersion(1.1) + '0.1')
		assert_equal('1.2', ImageVersion(1.1) + 0.1)

		assert_equal('1.0.0.0.1', ImageVersion(1) + ImageVersion('0.0.0.0.1'))

		assert_equal('1.2.3.4.5', ImageVersion(1) + ImageVersion(0.1) + ImageVersion('0.1.3') + ImageVersion('0.0.0.4.5'))
		assert_equal(ImageVersion('1.2.3.4.5'), ImageVersion(1) + ImageVersion(0.1) + ImageVersion('0.1.3') + ImageVersion('0.0.0.4.5'))

	def test_list_index(self):
		assert_equal(2, ImageVersion(2)[0])
		assert_equal(3, ImageVersion('1.2.3')[2])

		assert_equal(7, ImageVersion('8.5.4.7')[-1])
		assert_equal(2, ImageVersion('0.1.2.3')[-2])

		assert_raises(IndexError, lambda: ImageVersion(7.2)[3])

	def test_to_int(self):
		assert_equal(4, int(ImageVersion(4)))
		assert_equal(2, int(ImageVersion(2.5)))
		assert_equal(3, int(ImageVersion('3.0.0.0.1')))
		assert_equal(3, int(ImageVersion('3.9.9.9.9')))
