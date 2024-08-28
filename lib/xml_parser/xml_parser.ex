# lib/xml_parser/xml_parser.ex
defmodule XmlParser.XmlParser do
  import SweetXml

  def parse(xml_content) do
    cleaned_content = remove_bom(xml_content)
    parsed_xml = SweetXml.parse(cleaned_content)

    %{
      plaintiffs: safe_extract_plaintiffs(parsed_xml),
      defendants: safe_extract_defendants(parsed_xml)
    }
  end

  defp remove_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp remove_bom(content), do: content



  defp safe_extract_defendants(xml) do
    try do
      extract_defendant_details(xml)
    rescue
      _ -> "Error extracting defendants"
    end
  end

  defp safe_extract_plaintiffs(xml) do
    try do
      extract_plaintiffs(xml)
    rescue
      _ -> "Error extracting plaintiff"
    end
  end

  defp extract_plaintiffs(xml) do
    xml
    |> xpath(~x"//block"l,
      text: ~x"./text"o,
      pars: [
        ~x".//par"l,
        lines: [
          ~x".//line"l,
          formatting: ~x".//formatting/text()"sl
        ],
        has_plaintiff: ~x"boolean(.//formatting[starts-with(text(), 'Plaintiff,')])"b
      ]
    )
    |> Enum.find_value(&process_blocking/1)
  end

  defp process_blocking(%{text: _, pars: pars}) do
    pars
    |> Enum.reduce_while({[], false}, fn par, {acc, found} ->
      if found do
        {:halt, {acc, found}}
      else
        case process_par(par, acc) do
          {:found, new_acc} -> {:halt, {new_acc, true}}
          {:not_found, new_acc} -> {:cont, {new_acc, false}}
        end
      end
    end)
    |> case do
      {preceding_lines, true} -> extract_result(preceding_lines)
      _ -> nil
    end
  end

  defp process_par(%{lines: lines, has_plaintiff: true}, acc) do
    {plaintiff_line, preceding_lines} =
      Enum.split_with(lines, &Enum.any?(&1.formatting, fn text -> String.starts_with?(text, "Plaintiff,") end))
    new_acc = preceding_lines ++ acc
    {:found, Enum.reverse(new_acc) ++ plaintiff_line}
  end

  defp process_par(%{lines: lines, has_plaintiff: false}, acc) do
    {:not_found, lines ++ acc}
  end

  defp extract_result(lines) do
    {preceding_lines, [plaintiff_line | _]} = Enum.split_while(lines, fn line ->
      not Enum.any?(line.formatting, &String.starts_with?(&1, "Plaintiff,"))
    end)

    preceding_content_lines = preceding_lines
      |> Enum.reverse()
      |> Enum.reduce_while({[], 0}, fn line, {acc, length} ->
        line_content = Enum.join(line.formatting, " ")
        new_length = length + String.length(line_content)
        if new_length < 10 or length == 0 do
          {:cont, {[line_content | acc], new_length}}
        else
          {:halt, {[line_content | acc], new_length}}
        end
      end)
      |> elem(0)

    preceding_content = preceding_content_lines
      |> Enum.join(" ")
      |> String.trim()

    if String.length(preceding_content) >= 10 do
      preceding_content = String.slice(preceding_content, 0..999)
    end

    preceding_content
  end

  def extract_defendant_details(xml) do
    blocks = xpath(xml, ~x"//block"l,
      text: ~x"./text"o,
      pars: [
        ~x".//par"l,
        lines: [
          ~x".//line"l,
          formatting: ~x".//formatting/text()"sl
        ]
      ]
    )

    case find_defendant_content(blocks) do
      {:ok, content} -> parse_defendant_content(content)
      {:error, _} -> "Could not extract defendant details"
    end
  end

  defp find_defendant_content(blocks) do
    blocks
    |> Enum.reduce_while({[], false}, fn block, {acc, vs_found} ->
      block_content = extract_block_content(block)
      cond do
        String.contains?(block_content, "Defendants.") ->
          {:halt, {:ok, Enum.reverse([block_content | acc])}}
        vs_found ->
          {:cont, {[block_content | acc], vs_found}}
        String.contains?(block_content, "v.") or String.contains?(block_content, "vs.") ->
          {:cont, {[block_content | acc], true}}
        true ->
          {:cont, {acc, vs_found}}
      end
    end)
    |> case do
      {:ok, content} -> {:ok, content}
      _ -> {:error, "Could not find proper sequence of v./vs. and Defendants."}
    end
  end

  defp extract_block_content(block) do
    block.pars
    |> Enum.flat_map(fn par ->
      Enum.flat_map(par.lines, fn line ->
        line.formatting
      end)
    end)
    |> Enum.join(" ")
  end

  defp parse_defendant_content(content) do
    joined_content = Enum.join(content, " ")
    case Regex.run(~r/(?:v\.|vs\.)\s*.*?([A-Z][A-Z\s,-]+(?:,\s*INC\.)?.*?(?:inclusive,|inclusive\.))/s, joined_content) do
      [_, match] -> String.trim(match)
      _ -> "Could not extract valid defendant content"
    end
  end
end
