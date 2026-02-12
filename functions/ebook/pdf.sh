pdf_merge_files() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: pdf_merge_files -o output.pdf -i input1.pdf,input2.pdf[,input3.pdf...]"
    echo "Options:"
    echo "  -o   Specify the output PDF file."
    echo "  -i   Provide a comma-separated list of input PDF files to merge."
    return 0
  fi

  local output_file=""
  local input_files=""

  while getopts "o:i:" opt; do
    case $opt in
      o) output_file="$OPTARG" ;;
      i) input_files="$OPTARG" ;;
      *)
        echo "Invalid option"
        return 1
        ;;
    esac
  done

  if [[ -z $output_file || -z $input_files ]]; then
    echo "Error: Both -o and -i options are required."
    echo "Usage: pdf_merge_files -o output.pdf -i input1.pdf,input2.pdf[,input3.pdf...]"
    return 2
  fi

  IFS=',' read -r -a input_files_array <<<"$input_files"

  if ! command -v gs &>/dev/null; then
    echo "Error: Ghostscript (gs) is not installed." >&2
    return 3
  fi

  if gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output_file" "${input_files_array[@]}"; then
    echo "PDFs merged successfully into $output_file"
  else
    echo "Error: Failed to merge PDFs." >&2
    return 4
  fi
}
