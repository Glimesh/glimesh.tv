defmodule Glimesh.FileValidationTest do
  use Glimesh.DataCase

  @png_file "test/support/fixtures/files/200x200.png"
  @jpg_file "test/support/fixtures/files/200x200.jpg"
  @jpg_file "test/support/fixtures/files/200x200.jpg"

  describe "file validation" do
    test "validate/2 matches file types" do
      waffle_mock = %Waffle.File{
        path: @png_file
      }

      assert Glimesh.FileValidation.validate(waffle_mock, [:png])
      refute Glimesh.FileValidation.validate(waffle_mock, [:jpg])
    end

    test "validate_size/2 works properly" do
      waffle_mock = %Waffle.File{
        path: @png_file
      }

      assert Glimesh.FileValidation.validate_size(waffle_mock, 8000)
      refute Glimesh.FileValidation.validate_size(waffle_mock, 1024)
    end

    test "get_file_type/1 returns expected output" do
      assert {:ok, :png} ==
               Glimesh.FileValidation.get_file_type(@png_file)

      assert {:ok, :jpg} ==
               Glimesh.FileValidation.get_file_type(@jpg_file)

      assert {:ok, :unknown} ==
               Glimesh.FileValidation.get_file_type("test/test_helper.exs")

      assert {:error, "no such file or directory"} ==
               Glimesh.FileValidation.get_file_type("non-existant-file")
    end
  end

  describe "image validation" do
    test "validate_image/2 validates allowed options" do
      waffle_mock = %Waffle.File{
        path: @png_file
      }

      assert Glimesh.FileValidation.validate_image(waffle_mock, max_width: 200, max_height: 200)
      assert Glimesh.FileValidation.validate_image(waffle_mock, min_width: 200, min_width: 200)
      assert Glimesh.FileValidation.validate_image(waffle_mock, shape: :square)
    end

    test "validate_image/2 rejects unknown options" do
      waffle_mock = %Waffle.File{
        path: @png_file
      }

      assert_raise RuntimeError, "Shape validator not found for rectangle.", fn ->
        Glimesh.FileValidation.validate_image(waffle_mock, shape: :rectangle)
      end
    end
  end
end
