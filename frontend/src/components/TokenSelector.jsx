"use client";

import { ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";

const TOKEN_A_SYMBOL = "mETH";
const TOKEN_B_SYMBOL = "mSEI";

export default function TokenSelector({ value, onChange, disabled = false }) {
    const handleToggle = () => {
        const newValue = value === TOKEN_A_SYMBOL ? TOKEN_B_SYMBOL : TOKEN_A_SYMBOL;
        onChange(newValue);
    };

    return (
        <Button
            variant="secondary"
            className="gap-2 font-semibold min-w-[90px]"
            disabled={disabled}
            onClick={handleToggle}
            type="button"
        >
            {value}
            <ChevronDown className="h-4 w-4 opacity-50" />
        </Button>
    );
}
