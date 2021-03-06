module QueueryClient
  class DataFileBundle
    # abstract data_files :: [DataFile]

    def each_row(&block)
      data_files.each do |file|
        if file.data_object?
          file.each_row(&block)
        end
      end
    end

    alias each each_row
  end
end
